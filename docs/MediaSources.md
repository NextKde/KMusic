# Media sources: Navidrome / OpenSubsonic

The first integration supports one server/account at a time: connect, browse albums
(50 per page), open an album, search songs on that server (50 per page), show cover
art, play a song, and add songs to the existing queue. Jellyfin, WebDAV, remote
playlist editing, favorite synchronization and multi-server browsing are excluded.

Enter the server's root URL (including any reverse-proxy base path), username and
password in Media Sources. HTTPS is recommended. HTTP is allowed for local servers
but provides no transport encryption. Redirects are rejected; enter the final URL.

Authentication uses the Subsonic salted token protocol. Remembered credentials
use QtKeychain with insecure fallback disabled. If the credential store is not
available, the connection remains session-only and reports this. Disconnect disables
restoration and attempts credential deletion; failure is surfaced for retry.

Track identity includes the normalized server URL, account and remote song ID.
Queue/database records never contain passwords or signed playback URLs. Playback
requires connecting the matching server/account; it never falls back to NetEase or
other providers. Local-library views do not include server tracks.

For this initial implementation, audio is fetched into a local cache before the
existing GStreamer engine starts playback (up to 512 MiB per file). Initial playback
therefore waits for the download. Pause, resume and seeking use that local file.
Completed audio appears in the existing audio-cache management; active files are
protected. Cover files are fetched separately and are not deleted by audio cleanup.
Server lyrics and progressive network playback are not implemented.

## Automated checks

Build the opt-in runner:

```sh
cmake -S . -B build -DKMUSIC_BUILD_SUBSONIC_TESTS=ON
cmake --build build --target kmusic_subsonic_tests -j4
python tests/run_subsonic.py --audio-dir .task/local-test-audio
python tests/run_subsonic.py --audio-dir .task/local-test-audio --navidrome /absolute/path/to/navidrome
```

The runner creates isolated data/config/cache and a loopback server, uses generated
credentials, and re-encodes copies of the licensed test audio with deterministic
metadata. The original files and the user's current library are untouched. The
real-server mode starts and stops the supplied Navidrome binary; it does not install
a service. Reports stay under `.task/subsonic-test-*`. These are backend checks,
not visual acceptance. Protocol reference: https://opensubsonic.netlify.app/docs/
