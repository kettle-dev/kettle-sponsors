# Changelog

[![SemVer 2.0.0][📌semver-img]][📌semver] [![Keep-A-Changelog 1.0.0][📗keep-changelog-img]][📗keep-changelog]

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][📗keep-changelog],
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
and [yes][📌major-versions-not-sacred], platform and engine support are part of the [public API][📌semver-breaking].
Please file a bug if you notice a violation of semantic versioning.

[📌semver]: https://semver.org/spec/v2.0.0.html
[📌semver-img]: https://img.shields.io/badge/semver-2.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.1.1] - 2026-11-27

- TAG: [v0.1.1][0.1.1t]
- COVERAGE: 96.37% -- 717/744 lines in 18 files
- BRANCH COVERAGE: 80.32% -- 200/249 branches in 18 files
- 59.62% documented

### Added

- Embedded sponsor logo support (`logo` / `image_src` / `img_src`) via `Kettle::Sponsors::LogoLoader`: offline local file & `data:` URI base64 embedding by default, with opt-in cached remote HTTP(S) fetching (`fetch_logos: true` / `--fetch-logos`).
- Sponsorship `kind` support (`financial` default, `compute`, `time`, `services`) with crisp inline SVG vector icons (`Kettle::Sponsors::Icons`) and hybrid desktop (icon + label) / phone (top-right icon pill) layouts.
- Configurable badge theme (`Kettle::Sponsors::Theme`, `readme.sponsor_theme`): `background`, `border`, `text`, `muted`, `description`, `logo_background`, per-kind `accents`, `coin_metal` (`gold` / `silver`), `label_color`, `color`, CSS `font` stack (defaulting to `pboling/pboling`'s stack), and optional `font_file` character subsetting via `pyftsubset` (`Kettle::Sponsors::FontSubsetter`).
- Compact single-line Shields.io-style offline SVG badges (`Kettle::Sponsors::ShieldRenderer`, `Markup.shield` / `Markup.shields`, `<out>/shield/<slug>.svg`) supporting all five canonical styles (`flat`, `flat-square`, `plastic`, `for-the-badge`, `social`).
- Kind-specific CSS animations (`Kettle::Sponsors::Animations`, `animate: none | hover | always`, honoring `prefers-reduced-motion`): 3D metallic gold/silver coins (`financial`), ECG heartbeat sparkline (`compute`), glowing keyboard (`time`), and interlocking gears (`services`).

### Changed

- [kc] kettle-jem/prepare: updated 13 project files since the last release:
  - dependencies (13)

- [kc] kettle-jem/template: updated 10 project files since the last release:
  - dependencies (2)
  - documentation (1)
  - other (4)
  - workflows (3)

### Fixed

- Completed the user-managed `README.md` sections (`Synopsis`, `Configuration`, and `Basic Usage`) documenting `kettle-jem` plugin setup, sponsor configuration options, CLI usage, the Ruby API, and generated SVG badge examples hosted in `docs/images/`.

## [0.1.0] - 2026-11-26

- TAG: [v0.1.0][0.1.0t]
- COVERAGE: 96.84% -- 245/253 lines in 12 files
- BRANCH COVERAGE: 78.87% -- 56/71 branches in 12 files
- 68.42% documented
- Initial release

### Added

- kettle-jem-template-20260720-005 - README Support & Community links now
  include RubyForum.
- kettle-jem-template-20260726-001 - Projects now include YARD lint
  configuration and documentation dependencies so documentation issues fail
  before generated docs are refreshed.
- kettle-jem-template-20260727-001 - Spec harness documentation now lists the
  RSpec helpers provided by `kettle-test`.
- kettle-jem-template-20260913-001 - Templating now also surfaces a review
  entry in `dependency_conflicts.resolve` when a direct development
  dependency doesn't support one or more of this project's declared
  `engines:` and has no template-managed modular home (e.g. `sqlite3` on
  `jruby`). Review each entry and pick a resolution per the project's own
  engine support needs.

- Sponsor badge library: config loader, checksum-gated deterministic SVG renderer (desktop and phone), linked <picture> markup, central logos.galtzo.com URLs with local fallback, opt-in `--verify`, `kettle-sponsors` CLI, and a kettle-jem plugin

- `kettle-sponsors publish --from PATH --registry PATH` merges sponsors by slug into a central registry file (deterministic, idempotent)

### Changed

- [kc] kettle-jem/prepare: updated 6 project files:
  - configuration (1)
  - dependencies (5)

- kettle-jem-template-20260716-002 - Gemspecs now ship fewer repository-only
  files, reducing package noise for downstream packagers.
- kettle-jem-template-20260720-002 - Development Gemfiles now use the released
  `tree_sitter_language_pack` gem 1.13.3 or newer by default.
- kettle-jem-template-20260725-002 - Version specs now use `anonymous_loader` to
  cover `version.rb` without redefining constants, or are removed when version
  specs are not managed for the project.
- kettle-jem-template-20260801-001 - Generated README gem dashboard links now
  use ClickGems instead of BestGems.

- kettle-jem-template-20260728-001 - Generated Ruby workflows now use clearer
  setup-ruby-flash planning and can prepare appraisal-only jobs without
  installing the main Gemfile bundle.

- [kc] kettle-jem/template: updated 131 project files:
  - code and tests (7)
  - configuration (4)
  - dependencies (49)
  - documentation (4)
  - other (43)
  - workflows (24)

### Fixed

- kettle-jem-template-20260720-003 - StructuredMerge Git diff driver config now
  uses the installed `smorg-rb` driver command.
- kettle-jem-template-20260725-001 - Release pull request branches beginning
  with `feature/release` now run JRuby and TruffleRuby workflows.
- kettle-jem-template-20260726-002 - Generated version files now document their
  version namespace and constants, reducing warning-only YARD lint output.
- kettle-jem-template-20260726-003 - Coverage upload steps now treat Coveralls,
  QLTY, and Codecov as optional, so provider outages do not fail CI when local
  coverage thresholds still pass.
- kettle-jem-template-20260728-002 - Generated RuboCop configs now ignore the
  same `gemfiles/vendor/bundle` tree as `.gitignore`, so vendored dependency
  installs are not reported as project lint debt.
- kettle-jem-template-20260728-005 - VersionGem bootstrap now creates the
  missing canonical version spec when a project only has shim namespace version
  specs.
- kettle-jem-template-20260730-001 - Gemspec package file enumeration now runs
  relative to the gemspec directory, so release package contents stay correct
  even when the gemspec is loaded from another working directory.
- kettle-jem-template-20260801-002 - Generated RSpec helpers now normalize
  managed configuration block bindings structurally, preventing mixed block
  parameter names from producing invalid configuration after a merge.
- kettle-jem-template-20260801-003 - Generated project metadata and
  documentation now normalize configured underscore hostnames to valid
  hyphenated hostnames.
- kettle-jem-template-20260801-004 - Generated organization README logos now
  use GitHub's stable organization avatar endpoint instead of assuming a
  matching Galtzo-hosted asset exists.
- kettle-jem-template-20260802-001 - Devcontainer JSON files now merge as JSONC,
  preserving comments and trailing commas during template updates.

- kettle-jem-template-20260728-003 - Generated dep-heads workflows now run
  TruffleRuby jobs with current RubyGems and Bundler, avoiding setup failures
  before the test suite starts.
- kettle-jem-template-20260728-004 - Generated dep-heads workflows now use the
  setup-ruby Bundler install path for direct appraisal Gemfiles, avoiding rv
  lockfile parser failures on Git and path dependencies.

[Unreleased]: https://github.com/kettle-dev/kettle-sponsors/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/kettle-dev/kettle-sponsors/compare/v0.1.0...v0.1.1
[0.1.1t]: https://github.com/kettle-dev/kettle-sponsors/releases/tag/v0.1.1
[0.1.0]: https://github.com/kettle-dev/kettle-sponsors/compare/76b3a01f826cb55ef42436774feacc1991c66971...v0.1.0
[0.1.0t]: https://github.com/kettle-dev/kettle-sponsors/releases/tag/v0.1.0
