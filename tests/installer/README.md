# Local-source installer automation

Run only in a VM or disposable CI container, never on the developer host:

```sh
python3 -m unittest discover -s tests/installer -p test_local_source.py -v
```

Requires Python 3.9+, Git, CMake 3.21+ and Make. Tests use temporary directories,
a real local Git repository with bundled components and a manifest, and real CMake configure,
build and installation of a minimal executable fixture. Dependency detection is
injected for these focused lifecycle tests; they do not establish that the full
KMusic application builds or starts on the tested machine.

Coverage: relative `--source-dir .`, directory names with spaces, install/status,
repeat-install idempotency, committed-source updates, launcher rewriting,
manifest/source-type recording, uninstall/repeated uninstall, preservation of
user data, invalid/conflicting arguments, non-repository/subdirectory input,
missing provider/component, dirty source, invalid manifests, altered or extra vendor files,
dependency failure and failed-update preservation. A command guard rejects Git
fetch/clone/pull/checkout/submodule-update during local installation.

`run_local_install.py` additionally builds and installs **real KMusic** from an
ordinary checkout with bundled components, checks status/idempotency, then
uninstalls and checks user-data preservation. It uses separate XDG directories
and the same forbidden-Git-command guard. It does not launch the GUI or certify
visual appearance, playback or authentication.

The installer workflow runs the fixture suite in Arch, Ubuntu 26.04 and Debian 13
containers. Full-app local installation is added alongside the existing distro
installation matrix; Ubuntu 24.04 retains the dependency-rejection case. Package
provisioning belongs to these disposable CI fixtures, never to `install.sh`.
CI results must be checked for each run; adding a job does not mean it has passed.

`test_vendor_snapshot.py` covers exact-SHA imports, deterministic manifests, exclusion of Gallery/Git,
upstream dirty worktree isolation, missing/extra files, and refusal to overwrite downstream edits or import symlinks.
