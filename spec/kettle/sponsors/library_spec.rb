# frozen_string_literal: true

require "tmpdir"
require "stringio"

RSpec.describe Kettle::Sponsors do
  let(:today) { Date.new(2026, 11, 19) }
  let(:gh) { Kettle::Sponsors::Sponsor.from_h("name" => "GitHub", "url" => "https://github.com", "since" => "2026-08-29", "description" => "Copilot Max") }
  let(:expired) { Kettle::Sponsors::Sponsor.from_h("name" => "Old & Co", "target_href" => "https://old.example", "until" => "2026-01-01") }

  describe Kettle::Sponsors::Sponsor do
    it "normalizes aliases, slug and window" do
      expect(gh.href).to eq("https://github.com")
      expect(gh.slug).to eq("github")
      expect(gh).to be_active(today)
      expect(expired).not_to be_active(today)
    end

    it "rejects non-http links and unknown badge modes" do
      expect { described_class.from_h("name" => "X", "url" => "javascript:alert(1)") }.to raise_error(Kettle::Sponsors::Error)
      expect { described_class.from_h("name" => "X", "badge" => "nope") }.to raise_error(Kettle::Sponsors::Error)
    end
  end

  describe Kettle::Sponsors::Config do
    it "loads from kettle-jem.yml and detects slug collisions" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "c.yml")
        File.write(path, "readme:\n  corporate_sponsors:\n    - name: A B\n    - name: a-b\n")
        expect { described_class.load(path) }.to raise_error(Kettle::Sponsors::Error, /collision/)
        File.write(path, "sponsors:\n  - name: A\n")
        expect(described_class.load(path).map(&:name)).to eq(["A"])
        expect(described_class.load(File.join(dir, "missing.yml"))).to eq([])
      end
    end
  end

  describe Kettle::Sponsors::BadgeRenderer do
    it "is deterministic and escapes text" do
      a = described_class.svg(expired)
      expect(a).to eq(described_class.svg(expired))
      expect(a).to include("Old &amp; Co")
      expect(described_class.svg(gh, variant: :phone)).not_to eq(described_class.svg(gh))
    end
  end

  describe Kettle::Sponsors::Markup do
    it "wraps a responsive picture in an anchor, central by default" do
      html = described_class.badges([gh, expired], today: today)
      expect(html).to start_with('<a href="https://github.com"><picture>')
      expect(html).to include("https://logos.galtzo.com/assets/images/sponsors/phone/github.svg")
      expect(html).not_to include("old-co")
    end

    it "uses the local directory for local sponsors" do
      local = Kettle::Sponsors::Sponsor.from_h("name" => "Loc", "url" => "https://l.example", "badge" => "local")
      expect(described_class.badges([local], today: today)).to include('src="docs/assets/images/sponsors/loc.svg"')
    end
  end

  describe Kettle::Sponsors::Renderer do
    it "renders active sponsors once, then no-ops until the set changes" do
      Dir.mktmpdir do |dir|
        first = described_class.render([gh, expired], out: dir, today: today)
        expect(first.map { |p| File.basename(p) }).to eq(%w[github.svg github.svg])
        expect(described_class.render([gh, expired], out: dir, today: today)).to eq([])
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
      result = described_class.verify([gh, expired, local], today: today, http: ->(u) { seen << u; true })
      expect(seen.size).to eq(2)
      expect(result.values).to all(be(true))
    end
  end

  describe Kettle::Sponsors::CLI do
    it "--check exits 1 when stale and 0 when current" do
      Dir.mktmpdir do |dir|
        cfg = File.join(dir, "c.yml")
        out = File.join(dir, "out")
        File.write(cfg, "sponsors:\n  - name: GitHub\n    url: https://github.com\n")
        io = StringIO.new
        args = ["--config", cfg, "--out", out]
        expect(described_class.new(args + ["--check"], out: io).run).to eq(1)
        expect(described_class.new(args.dup, out: io).run).to eq(0)
        expect(described_class.new(args + ["--check"], out: io).run).to eq(0)
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
        expect(recorded.map(&:first)).to eq(%w[loc.svg loc.svg])
      end
    end
  end
end

RSpec.describe Kettle::Sponsors::Verifier do
  it "treats network failures as unreachable" do
    allow(Net::HTTP).to receive(:start).and_raise(SocketError)
    expect(described_class.head("https://logos.galtzo.com/x.svg")).to be(false)
  end
end
