# Pinned shared UI source

[简体中文](SharedUi.zh-CN.md)

KMusic vendors an exact Kos.Ui snapshot instead of a Git submodule. A normal clone
includes components, GLSL/QSB, translations and licenses; Gallery, demo assets and
upstream Git history are excluded. The initial pin remains
`dfeddc18f5b1fe529383a7391c2fb52d54b6adee`; no visual tuning is part of this migration.

`vendor/nextkdeAppDemo/vendor-manifest.json` records the repository, full SHA and
per-file SHA-256. LICENSE, NOTICE.md and source attribution remain intact.
Shared component development stays upstream; application behavior stays in KMusic.
Do not hand-edit the generated snapshot. Its integrity check detects changes and
the importer refuses to overwrite them.

Import a reviewed commit from an existing local upstream clone:

```sh
python3 tools/vendor_components.py --upstream-dir /path/to/nextkdeAppDemo --revision <full-40-character-SHA>
```

The tool reads committed Git objects only, never fetches and excludes uncommitted
upstream work. It imports only shared/qml, LICENSE and NOTICE.md, plus a generated
manifest. Commit changes together in a PR; build/install tests and user visual
acceptance remain necessary. Revert the complete sync commit to roll back.
Run checks/tests only in VM or CI:

```sh
python3 tools/vendor_components.py --check
python3 -m unittest discover -s tests/installer -p 'test_*.py' -v
```

The `Sync pinned Kos.Ui snapshot` workflow accepts manual `revision` input and
`repository_dispatch` event `kos-ui-sync` with `client_payload.revision`. It reads
only the official upstream repository, accepts full SHAs only and updates one
`codex/sync-kos-ui` branch/PR. It serializes sync runs, creates no empty commit and
never merges main automatically. It must first reach the default branch and the
repository must allow Actions to create PRs. Cross-repository upstream dispatch
requires a separately configured GitHub App/token Secret; this change does not
configure credentials or modify upstream. Manual sync works without that upstream
notification setup. Bot PR checks may need GitHub approval; creating a PR is not
proof that checks passed.

Local installation verifies the bundled manifest and never initializes/downloads
components. Missing or altered snapshots fail INTEGRITY_FAILED. Explicit older
remote --version revisions retain compatibility with the former submodule layout.
