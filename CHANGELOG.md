# Changelog

Changelogs for Unclog.

## Unreleased

Monday, May 04, 2026

### Bug fixes

 - Do not include empty subheaders if the files are empty.
 - Fix typo in scaffold comment.
 - Fix duplicate assignment in `make_release` that produced a compiler warning.
 - Drop redundant `File.touch` before `File.write` in scaffold.
 - Make `init` scaffolding idempotent without clobbering an existing preamble.
 - Correct mislabeled `@spec` on `write_changelog/1`.
 - Remove dead `put_in` branch in `nest_changelog`.
 - Honor `:unclog, :root` and `:unclog, :output` env in `init` and `write_changelog` (no more hardcoded paths).
 - Print usage instead of silently exiting when `mix unclog` is run without flags.


## 0.1.1

Monday, April 27, 2026

 - Remove Timex dependency

## 0.1.0

Wednesday, April 16, 2025

Created the first release of Unclog for Elixir 🥳

### Features

 - Scaffolding for releases.
 - Scaffolding for `.changelogs`
 - Mix task
