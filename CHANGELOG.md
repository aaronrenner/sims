# Changelog

## [0.2.0] - 2026-06-04

### Changed

- Updated generated HTTP simulator routers to use Plug's `copy_opts_to_assign`
  option for carrying router init options through request handling.

### Maintenance

- Updated CI dependencies:
  - `actions/cache` from 4 to 5.
  - `erlef/setup-beam` from 1.20 to 1.24.
- Updated the development documentation dependency `ex_doc` from 0.39.1 to
  0.40.1.

## [0.1.0] - 2025-10-24

### Added

- Initial Hex package release for Sims, including package metadata and
  documentation source links.

[0.2.0]: https://github.com/aaronrenner/sims/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/aaronrenner/sims/releases/tag/v0.1.0
