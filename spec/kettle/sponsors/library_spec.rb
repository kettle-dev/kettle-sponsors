# frozen_string_literal: true

require "tmpdir"
require "stringio"

RSpec.describe Kettle::Sponsors do
  let(:today) { Date.new(2026, 11, 19) }
  let(:svg_logo_data) do
    "data:image/svg+xml;base64,#{['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><circle cx="5" cy="5" r="4"/></svg>'].pack("m0")}"
  end
  let(:gh) do
    Kettle::Sponsors::Sponsor.from_h(
      "name" => "GitHub",
      "url" => "https://github.com",
      "since" => "2026-08-29",
      "description" => "Copilot Max",
      "kind" => "compute",
      "logo" => svg_logo_data
    )
  end
  let(:expired) do
    Kettle::Sponsors::Sponsor.from_h(
      "name" => "Old & Co",
      "target_href" => "https://old.example",
      "until" => "2026-01-01"
    )
  end

  describe Kettle::Sponsors::Sponsor do
    it "normalizes aliases, kind, logo, slug and window" do
      expect(gh.href).to eq("https://github.com")
      expect(gh.slug).to eq("github")
      expect(gh.kind).to eq("compute")
      expect(gh.logo).to eq(svg_logo_data)
      expect(gh).to be_active(today)
      expect(expired).not_to be_active(today)
      expect(expired.kind).to eq("financial")
    end

    it "accepts image_src and img_src aliases for logo" do
      s1 = described_class.from_h("name" => "A", "image_src" => "logos/a.svg")
      s2 = described_class.from_h("name" => "B", "img_src" => "https://example.com/b.png")
      expect(s1.logo).to eq("logos/a.svg")
      expect(s2.logo).to eq("https://example.com/b.png")
    end

    it "rejects invalid links, badge modes, kinds, dates, and logo schemes" do
      expect { described_class.from_h("name" => "") }.to raise_error(Kettle::Sponsors::Error)
      expect { described_class.from_h("name" => "X", "url" => "javascript:alert(1)") }.to raise_error(Kettle::Sponsors::Error)
      expect { described_class.from_h("name" => "X", "badge" => "nope") }.to raise_error(Kettle::Sponsors::Error)
      expect { described_class.from_h("name" => "X", "kind" => "magic") }.to raise_error(Kettle::Sponsors::Error)
      expect { described_class.from_h("name" => "X", "since" => "not-a-date") }.to raise_error(Kettle::Sponsors::Error)
      expect { described_class.from_h("name" => "X", "logo" => "javascript:alert(1)") }.to raise_error(Kettle::Sponsors::Error)
    end
  end

  describe Kettle::Sponsors::Theme do
    it "uses pboling sans font stack and gold coins by default" do
      theme = described_class.new
      expect(theme.font).to eq(described_class::DEFAULT_FONT)
      expect(theme.background).to eq("#0d1117")
      expect(theme.coin_metal).to eq("gold")
      expect(theme.coin_palette[:face_mid]).to eq("#f5c542")
      expect(theme.animate).to eq("none")
      expect(theme).not_to be_animated
      expect(theme).not_to be_fetch_logos
    end

    it "supports custom colors, silver coins, accents, and #with overrides" do
      theme = described_class.from_h(
        "background" => "#14211f",
        "border" => "#25403c",
        "text" => "#f4efe4",
        "muted" => "#8fa6a1",
        "description" => "#c8d6d3",
        "logo_background" => "transparent",
        "coin_metal" => "silver",
        "accents" => {"compute" => "#4fc3b3"},
        "animate" => "hover",
        "shield_style" => "for-the-badge",
        "fetch_logos" => true
      )
      expect(theme.accent_for("compute")).to eq("#4fc3b3")
      expect(theme.accent_for("financial")).to eq("#3fb950")
      expect(theme.coin_palette[:face_mid]).to eq("#d0d7de")
      expect(theme).to be_animated
      expect(theme).to be_fetch_logos

      copy = theme.with(animate: "always", shield_style: "social")
      expect(copy.animate).to eq("always")
      expect(copy.shield_style).to eq("social")
      expect(copy.background).to eq("#14211f")
    end

    it "rejects invalid animate, shield_style, and coin_metal values" do
      expect { described_class.new(animate: "bounce") }.to raise_error(Kettle::Sponsors::Error)
      expect { described_class.new(shield_style: "round") }.to raise_error(Kettle::Sponsors::Error)
      expect { described_class.new(coin_metal: "bronze") }.to raise_error(Kettle::Sponsors::Error)
    end
  end

  describe Kettle::Sponsors::Config do
    it "loads sponsors and theme from kettle-jem.yml and detects slug collisions" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "c.yml")
        File.write(path, "readme:\n  corporate_sponsors:\n    - name: A B\n    - name: a-b\n")
        expect { described_class.load(path) }.to raise_error(Kettle::Sponsors::Error, /collision/)

        File.write(path, <<~YAML)
          readme:
            sponsor_theme:
              background: "#111111"
              animate: always
            corporate_sponsors:
              - name: A
                kind: time
        YAML
        loaded = described_class.load_all(path)
        expect(loaded[:sponsors].map(&:name)).to eq(["A"])
        expect(loaded[:sponsors].first.kind).to eq("time")
        expect(loaded[:theme].background).to eq("#111111")
        expect(loaded[:theme].animate).to eq("always")
        expect(described_class.load(File.join(dir, "missing.yml"))).to be_empty
        expect(described_class.load_theme(File.join(dir, "missing.yml")).background).to eq("#0d1117")
      end
    end
  end

  describe Kettle::Sponsors::LogoLoader do
    let(:png_bytes) { "\x89PNG\r\n\x1A\nfake-png".b }
    let(:jpg_bytes) { "\xFF\xD8\xFFfake-jpg".b }
    let(:webp_bytes) { "RIFF\x00\x00\x00\x00WEBPfake".b }

    it "passes through data URIs and resolves local files relative to base_dir" do
      expect(described_class.resolve(nil)).to be_nil
      expect(described_class.resolve(svg_logo_data)).to eq(svg_logo_data)

      Dir.mktmpdir do |dir|
        File.binwrite(File.join(dir, "logo.png"), png_bytes)
        File.binwrite(File.join(dir, "logo.jpg"), jpg_bytes)
        File.binwrite(File.join(dir, "logo.webp"), webp_bytes)
        File.write(File.join(dir, "logo.svg"), '<svg xmlns="http://www.w3.org/2000/svg"></svg>')

        expect(described_class.resolve("logo.png", base_dir: dir)).to start_with("data:image/png;base64,")
        expect(described_class.resolve("logo.jpg", base_dir: dir)).to start_with("data:image/jpeg;base64,")
        expect(described_class.resolve("logo.webp", base_dir: dir)).to start_with("data:image/webp;base64,")
        expect(described_class.resolve("logo.svg", base_dir: dir)).to start_with("data:image/svg+xml;base64,")
        expect(described_class.resolve("missing.png", base_dir: dir)).to be_nil
      end
    end

    it "skips remote URLs offline, and fetches and caches them when fetch: true" do
      url = "https://example.com/brand.png"
      expect(described_class.resolve(url, fetch: false)).to be_nil

      Dir.mktmpdir do |cache|
        calls = 0
        fetcher = lambda do |_u|
          calls += 1
          [png_bytes, "image/png"]
        end

        first = described_class.resolve(url, fetch: true, cache_dir: cache, http: fetcher)
        second = described_class.resolve(url, fetch: true, cache_dir: cache, http: fetcher)
        refreshed = described_class.resolve(url, fetch: true, cache_dir: cache, refresh: true, http: fetcher)

        expect(first).to start_with("data:image/png;base64,")
        expect(second).to eq(first)
        expect(refreshed).to eq(first)
        expect(calls).to eq(2)
      end
    end

    it "returns nil when remote fetch fails" do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError)
      expect(described_class.resolve("https://example.com/fail.png", fetch: true)).to be_nil
    end
  end

  describe Kettle::Sponsors::FontSubsetter do
    it "subsets via pyftsubset to only unique characters and embeds @font-face" do
      Dir.mktmpdir do |dir|
        font = File.join(dir, "Custom-Sans.ttf")
        File.binwrite(font, "FULL-FONT-BYTES")

        invoked = []
        fake_runner = lambda do |argv|
          invoked << argv
          out_arg = argv.find { |a| a.start_with?("--output-file=") }
          File.binwrite(out_arg.delete_prefix("--output-file="), "SUBSET-WOFF2")
          ["", "", true]
        end

        result = described_class.css_for(font_file: font, text: "Acme Acme!", runner: fake_runner)
        expect(result[:subsetted]).to be(true)
        expect(result[:family]).to eq("Custom-Sans")
        expect(result[:chars]).to eq(" !Aランク".delete("ランク") + "cem")
        expect(invoked.first).to include("--text= !Acem", "--flavor=woff2")
        expect(result[:css]).to include("font-family:'Custom-Sans'", "data:font/woff2;base64,", "format('woff2')")
      end
    end

    it "falls back to raw subset then full font when pyftsubset is unavailable" do
      Dir.mktmpdir do |dir|
        font = File.join(dir, "my.ttf")
        File.binwrite(font, "RAW-TTF")

        no_tool = ->(_argv) { raise Errno::ENOENT }
        fallback = described_class.css_for(font_file: font, text: "Hi", runner: no_tool)
        expect(fallback[:subsetted]).to be(false)
        expect(fallback[:css]).to include("data:font/ttf;base64,", "format('truetype')")

        raw_only = lambda do |argv|
          next ["", "no brotli", false] if argv.include?("--flavor=woff2")

          out_arg = argv.find { |a| a.start_with?("--output-file=") }
          File.binwrite(out_arg.delete_prefix("--output-file="), "SUBSET-TTF")
          ["", "", true]
        end
        raw_sub = described_class.css_for(font_file: font, text: "Hi", runner: raw_only)
        expect(raw_sub[:subsetted]).to be(true)
        expect(raw_sub[:css]).to include("data:font/ttf;base64,")
      end
    end

    it "raises on missing or unsupported font files" do
      expect { described_class.css_for(font_file: "/no/such/font.ttf", text: "A") }.to raise_error(Kettle::Sponsors::Error, /not found/)
      Dir.mktmpdir do |dir|
        bad = File.join(dir, "font.txt")
        File.write(bad, "x")
        expect { described_class.css_for(font_file: bad, text: "A") }.to raise_error(Kettle::Sponsors::Error, /unsupported/)
      end
    end
  end

  describe Kettle::Sponsors::BadgeRenderer do
    it "is deterministic, escapes text, embeds logo, and uses hybrid desktop/phone layout" do
      a = described_class.svg(expired)
      expect(a).to eq(described_class.svg(expired))
      expect(a).to include("Old &amp; Co", "Financial · sponsor")

      desktop = described_class.svg(gh, variant: :desktop)
      phone = described_class.svg(gh, variant: :phone)
      expect(desktop).to include("Compute · since 2026-08", svg_logo_data)
      expect(phone).not_to include("Compute ·")
      expect(phone).to include("since 2026-08", svg_logo_data)
    end

    it "renders animations for every kind in hover and always modes" do
      %w[financial compute time services].each do |kind|
        sp = Kettle::Sponsors::Sponsor.from_h("name" => "S #{kind}", "kind" => kind, "description" => "Desc")
        hover_svg = described_class.svg(sp, theme: Kettle::Sponsors::Theme.new(animate: "hover"))
        always_svg = described_class.svg(sp, theme: Kettle::Sponsors::Theme.new(animate: "always"))
        expect(hover_svg).to include("svg:hover", "prefers-reduced-motion:reduce")
        expect(always_svg).not_to include("svg:hover")
        expect(always_svg).to include("prefers-reduced-motion:reduce")
      end

      silver_svg = described_class.svg(
        expired,
        theme: Kettle::Sponsors::Theme.new(animate: "always", coin_metal: "silver")
      )
      expect(silver_svg).to include("#d0d7de", "ks-coin-face")
    end

    it "delegates :shield variant to ShieldRenderer and rejects unknown variants" do
      shield = described_class.svg(gh, variant: :shield)
      expect(shield).to include("compute", "GitHub")
      expect { described_class.svg(gh, variant: :unknown) }.to raise_error(ArgumentError)
    end
  end

  describe Kettle::Sponsors::ShieldRenderer do
    it "renders all 5 Shields.io styles offline with embedded logos" do
      Kettle::Sponsors::Theme::SHIELD_STYLES.each do |style|
        svg = described_class.svg(gh, style: style)
        expect(svg).to include("<svg", svg_logo_data)
        expected_text = (style == "for-the-badge") ? "GITHUB" : "GitHub"
        expect(svg).to include(expected_text)
      end
      expect { described_class.svg(gh, style: "invalid") }.to raise_error(Kettle::Sponsors::Error)
    end
  end

  describe Kettle::Sponsors::Markup do
    it "wraps a responsive picture in an anchor, central by default" do
      html = described_class.badges([gh, expired], today: today)
      expect(html).to start_with('<a href="https://github.com"><picture>')
      expect(html).to include("https://logos.galtzo.com/assets/images/sponsors/phone/github.svg")
      expect(html).not_to include("old-co")
    end

    it "uses the local directory for local sponsors and builds compact shield parades" do
      local = Kettle::Sponsors::Sponsor.from_h("name" => "Loc", "url" => "https://l.example", "badge" => "local", "kind" => "services")
      unlinked = Kettle::Sponsors::Sponsor.from_h("name" => "Bare", "badge" => "local")
      expect(described_class.badges([local], today: today)).to include('src="docs/assets/images/sponsors/loc.svg"')

      parade = described_class.shields([local, unlinked, expired], today: today)
      expect(parade).to include('<a href="https://l.example"><img src="docs/assets/images/sponsors/shield/loc.svg" alt="services: Loc"></a>')
      expect(parade).to include('<img src="docs/assets/images/sponsors/shield/bare.svg" alt="sponsor: Bare">')
      expect(parade).not_to include("old-co")
    end
  end

  describe Kettle::Sponsors::Renderer do
    it "renders desktop, phone, and shield SVGs once, then no-ops until sponsors or theme change" do
      Dir.mktmpdir do |dir|
        first = described_class.render([gh, expired], out: dir, today: today)
        expect(first.map { |p| File.basename(p) }).to eq(%w[github.svg github.svg github.svg])
        expect(described_class.render([gh, expired], out: dir, today: today)).to be_empty
        expect(described_class.stale?([gh, expired], out: dir, today: today, theme: Kettle::Sponsors::Theme.new(animate: "hover"))).to be(true)
        expect(described_class.stale?([], out: dir, today: today)).to be(true)
        described_class.render([], out: dir, today: today)
        expect(Dir[File.join(dir, "**/*.svg")]).to be_empty
      end
    end
  end

  describe Kettle::Sponsors::Verifier do
    it "checks only active central sponsors" do
      local = Kettle::Sponsors::Sponsor.from_h("name" => "Loc", "badge" => "local")
      seen = []
      result = described_class.verify([gh, expired, local], today: today, http: ->(u) {
        seen << u
        true
      })
      expect(seen.size).to eq(2)
      expect(result.values).to all(be(true))
    end

    it "treats network failures as unreachable" do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError)
      expect(described_class.head("https://logos.galtzo.com/x.svg")).to be(false)
    end
  end

  describe Kettle::Sponsors::CLI do
    it "--check exits 1 when stale and 0 when current, and supports theme CLI flags" do
      Dir.mktmpdir do |dir|
        cfg = File.join(dir, "c.yml")
        out = File.join(dir, "out")
        File.write(cfg, "sponsors:\n  - name: GitHub\n    url: https://github.com\n    kind: compute\n")
        io = StringIO.new
        args = ["--config", cfg, "--out", out, "--animate", "hover", "--shield-style", "plastic", "--coin-metal", "silver"]
        expect(described_class.new(args + ["--check"], out: io).run).to eq(1)
        expect(described_class.new(args.dup, out: io).run).to eq(0)
        expect(described_class.new(args + ["--check"], out: io).run).to eq(0)
        expect(File.read(File.join(out, "github.svg"))).to include("svg:hover")
        expect(File.read(File.join(out, "shield", "github.svg"))).to include('height="18"')
      end
    end
  end

  describe Kettle::Sponsors::Plugin do
    it "registers an after-remaining_files hook" do
      registrar = double("registrar")
      expect(registrar).to receive(:after_phase).with(:remaining_files)
      Kettle::Sponsors.register_kettle_jem_plugin(registrar)
    end

    it "renders only local sponsors and records the files" do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(File.join(dir, ".structuredmerge"))
        File.write(File.join(dir, Kettle::Sponsors::CONFIG_PATH), "readme:\n  corporate_sponsors:\n    - name: Loc\n      badge: local\n    - name: Cen\n")
        recorded = []
        helpers = double("helpers")
        allow(helpers).to receive(:record_template_result) { |p, a| recorded << [File.basename(p), a] }
        context = double("context", project_root: dir, helpers: helpers, out: double("out", report_detail: nil, warning: nil))
        described_class.render_local(context)
        expect(recorded.map(&:first)).to eq(%w[loc.svg loc.svg loc.svg])
      end
    end
  end

  describe Kettle::Sponsors::Registry do
    def write(path, yaml)
      File.write(path, yaml)
    end

    it "merges by slug (incoming wins), keeps registry-only entries, sorts, and is idempotent" do
      Dir.mktmpdir do |dir|
        from = File.join(dir, "family.yml")
        reg = File.join(dir, "sub", "sponsors.yml")
        write(from, "readme:\n  corporate_sponsors:\n    - name: GitHub\n      target_href: https://github.com\n      image_src: https://x/y.png\n      kind: compute\n      until: 2027-01-01\n")
        FileUtils.mkdir_p(File.dirname(reg))
        write(reg, "sponsors:\n  - name: Zeta\n    target_href: https://z.example\n  - name: GitHub\n    target_href: https://old.example\n")

        expect(described_class.publish(from: from, registry: reg)).to be(true)
        sponsors = Kettle::Sponsors::Config.load(reg)
        expect(sponsors.map(&:slug)).to eq(%w[github zeta])
        expect(sponsors.first.href).to eq("https://github.com")
        expect(sponsors.first.logo).to eq("https://x/y.png")
        expect(sponsors.first.kind).to eq("compute")
        expect(sponsors.first.until_date).to eq(Date.new(2027, 1, 1))
        expect(File.read(reg)).to include("logo: https://x/y.png")
        expect(File.read(reg)).not_to include("image_src")
        expect(described_class.publish(from: from, registry: reg)).to be(false)
      end
    end

    it "refuses an empty source" do
      Dir.mktmpdir do |dir|
        from = File.join(dir, "e.yml")
        File.write(from, "{}\n")
        expect { described_class.publish(from: from, registry: File.join(dir, "r.yml")) }.to raise_error(Kettle::Sponsors::Error)
      end
    end

    it "is driven by the CLI publish subcommand" do
      Dir.mktmpdir do |dir|
        from = File.join(dir, "f.yml")
        reg = File.join(dir, "r.yml")
        File.write(from, "corporate_sponsors:\n  - name: A\n    url: https://a.example\n")
        io = StringIO.new
        expect(Kettle::Sponsors::CLI.new(["publish", "--from", from, "--registry", reg], out: io).run).to eq(0)
        expect(io.string).to include("registry updated")
        expect(Kettle::Sponsors::CLI.new(["publish"], out: io).run).to eq(2)
      end
    end
  end
end
