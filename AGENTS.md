# Contributor instructions

This is the independent NextKde Music desktop application. Read docs/Design.md
and docs/Roadmap.md before changing the UI. The coordinating chat owns design
and acceptance; one implementation subagent owns application and component work.

- Never build, launch, run tests, bake shaders, or perform graphical verification
  on the maintainer workstation. All runtime work is VM-only. Host source review,
  edits, and Git operations are allowed. Do not start or replace the host Shell.
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
- Keep temporary logs, screenshots and acceptance records in ignored .task/.
  Record exact app/component revisions and VM environment for runtime evidence.
  Source review and successful builds do not establish visual acceptance.
- English documentation has maintained Chinese companions. No release tag or
  claim of completed acceptance until the coordinating designer signs off.
