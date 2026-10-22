# Contributor instructions

- Latest design authority: read docs/DesignReset.zh-CN.md (English companion
  docs/DesignReset.md). The user requires pure QML transparency/blur and retained
  liquid effects; the previous KWin/KF6/native review route is retired. Whole-app
  design acceptance must be redone with Apple Music content, kos-settings exterior
  and self-drawn decoration, and Forma component detail.

This is the independent NextKde Music desktop application. Read docs/Design.md
and docs/Roadmap.md before changing the UI. The coordinating chat owns design
and acceptance; one implementation subagent owns application and component work.

- The user explicitly authorized local testing and screenshots for THIS task on
  2026-10-20, superseding the earlier VM-only preference. Use dedicated application
  and Gallery windows, isolated app data and processes; do not start or replace
  the desktop Shell or modify KWin. Builds, relevant tests and shader baking may
  run locally for this task after the user approves the revised project plan.
- User approved docs/ProjectPlan.zh-CN.md and said to start on 2026-10-20.
  Development, local builds/testing/screenshots and scheduled publication are ACTIVE.
- Use the actual portable Kos.Ui components from NextKde/nextkdeAppDemo, pinned
  through a Git submodule. Do not fork component visuals inside this application.
  General control fixes belong upstream; business logic belongs here.
- Before editing nextkdeAppDemo, follow its AGENTS.md and architecture documents.
  Preserve host-owned state, public signals, exports, and matching shader assets.
- Apple Music supplies information architecture. Forma supplies visual control
  references. kos-settings supplies square window chrome with controls on the right.
  The window radius is zero; individual control geometry follows the reference.
- Preserve original licenses and record source provenance. Use original fixture
  art and local/authorized audio. A catalogue fixture is not a streaming service.
- Keep unrelated changes in the existing NextKde checkout untouched.
- Keep temporary logs and internal records in ignored .task/. After plan approval,
  every actual five-minute follow-up captures fresh KMusic and Gallery screenshots
  and publishes each to its corresponding repository's ui-evidence branch.
  Record exact app/component revisions and local environment for runtime evidence.
- Every 15 minutes also push current source progress with latest screenshots:
  app branch codex/music-development, component branch codex/music-fidelity.
  Track last_source_push_at and successful remote publication; label incomplete
  and unverified work. Expose a stable latest-progress link from each README.
  Source review and successful builds do not establish visual acceptance.
- Audio source integration follows SPlayer-Dev/SPlayer-Next, initially its NetEase
  search/detail/lyrics/play-URL flow. Preserve source identities and explicit
  trial/unavailable/auth failures. Do not silently substitute the legacy LX source.
- Public app/repository name is KMusic / NextKde/KMusic. Local source is
  /home/amao/OneDrive/KMusic. Preserve this repository history.
- English documentation has maintained Chinese companions. No release tag or
  claim of completed acceptance until the coordinating designer signs off.
