# Local audio integration fixtures

Download these separately; audio is not committed:

- **The Entertainer**, Scott Joplin, performed by Wikimedia user IE (2007).
  Recording released into the public domain worldwide by the performer.
  Source: https://commons.wikimedia.org/wiki/File:The_Entertainer_-_Scott_Joplin.ogg
  Audio: https://upload.wikimedia.org/wikipedia/commons/1/1b/The_Entertainer_-_Scott_Joplin.ogg
- **Maple Leaf Rag**, first-page performance excerpt, recorded 2007 by Foil Fencer2.
  Wikimedia Commons marks the file as public domain.
  Source: https://commons.wikimedia.org/wiki/File:Maple_Leaf_Rag.ogg
  Audio: https://upload.wikimedia.org/wikipedia/commons/f/fe/Maple_Leaf_Rag.ogg

Build with `cmake -S . -B build -DKMUSIC_BUILD_LOCAL_TESTS=ON` and
`cmake --build build --target kmusic_local_tests -j4`. Run explicitly with
`python tests/run_local_music.py --audio-dir .task/local-test-audio`.

The runner creates a fresh data/cache/config directory and private D-Bus session.
It exercises the real MusicController, SQLite library, TagLib scanner and GStreamer
playback with volume zero, not a fake audio clock. It never opens the main app,
captures screenshots, imports into the user's library, or deletes fixture files.
JSON results and diagnostic logs remain in `.task/local-integration-*/`.
This is backend integration coverage, not visual acceptance or a speaker-output test.

## 中文

音频来源、作者和许可见上方；下载文件不提交到 Git。第一首为完整演奏，第二首为片段。
仅按需执行：测试使用独立数据、缓存、配置和 D-Bus 会话。实际调用正式曲库、扫描器与
GStreamer 解码播放链路，音量设为零。覆盖后端集成，不代表界面验收或扬声器听感验收。
测试不打开主界面、不截图、不修改用户曲库，也不删除下载的音频。
