# Isolated input interaction checks

This target builds the real shared Kos.Ui module and KMusic input/button/theme
wrappers without the player backend. It requires Qt 6.8+ development tools,
QuickTest and the QtTest/Controls/Effects/Qt5Compat runtime QML modules, but no
GStreamer, TagLib, QR or account dependencies.

Run only in the authorized test VM:

```sh
cmake -S tests/ui -B build-input-tests -G Ninja
cmake --build build-input-tests --parallel 2
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  ./build-input-tests/kmusic_input_tests -input tests/ui
```

The checks exercise keyboard entry, the actual clear button and focus restoration,
opaque light/dark plain-field colors, and recovery of malformed persistent search
history (invalid JSON/list types, invalid entries, duplicates and size limits). Offscreen software rendering provides
interaction evidence only; it does not validate liquid optics, final appearance,
whole-app imports, playback, or native desktop integration. No account data is
loaded by this fixture.
