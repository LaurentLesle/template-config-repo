# Changelog

All notable changes to this infrastructure configuration are documented in this file.

This changelog is automatically updated by the [changelog workflow](.github/workflows/changelog.yml)
when a new release is published.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

<!-- CHANGELOG:START - Do not remove this marker -->

## [v1.0.1] — 2026-04-08

### What's Changed

- **Auto-discover environments** — `deploy.yml` now scans `configurations/env-*/config.yaml` dynamically instead of using a hardcoded dev/prod matrix. Add or remove environment directories without editing the workflow.
- **Sync GitHub Environments** — new `sync-environments.yml` workflow auto-creates GitHub Environments on push to main, keeping Settings → Environments in sync with config directories.
- **Bump to galaxy v1.0.2** — references updated to `LaurentLesle/terraform-rest-galaxy@v1.0.2` which supports arbitrary environment names.
- **Copilot instructions** — documented auto-discovery model and added upstream search constraint to prevent searches outside the galaxy repo.

**Full Changelog**: https://github.com/LaurentLesle/template-config-repo/compare/v1.0.0...v1.0.1


<!-- CHANGELOG:END - Do not remove this marker -->
