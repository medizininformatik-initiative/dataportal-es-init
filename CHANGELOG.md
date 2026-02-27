# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-02-27
### Added
- Compare installed version and update candidate version of the ontology and only update newer files
- FORCE_REINSTALL parameter added to override the version nr check and always delete and reinstall
### Changed
- BREAKING: Since the version numbers in the ontology files are only provided from 4.0.0 up, this is required. For older versions use 1.x of this tool
### Removed
- EXIT_ON_EXISTING_INDICES parameter is obsolete since the version check makes more sense

## [1.2.1] - 2025-01-21
### Changed
- The option to use a mounted file is now implicit

## [1.2.0] - 2025-01-14
### Added
- Option to use local files instead of downloading

## [1.1.0] - 2024-12-10
### Changed
- Default download path changed to release assets

## [1.0.0] - 2024-11-12

### Added
- initial release

