cmake_minimum_required(VERSION 3.21)
project(KMusic VERSION 0.1.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
include(GNUInstallDirs)
find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 QuickDialogs2 Concurrent DBus Network Sql)
find_package(PkgConfig REQUIRED)
find_package(Qt6Keychain REQUIRED)
pkg_check_modules(MUSIC_QRENCODE REQUIRED IMPORTED_TARGET libqrencode)
pkg_check_modules(MUSIC_GSTREAMER REQUIRED IMPORTED_TARGET gstreamer-1.0 gstreamer-audio-1.0 gstreamer-pbutils-1.0)
pkg_check_modules(MUSIC_TAGLIB REQUIRED IMPORTED_TARGET taglib>=1.12)
qt_standard_project_setup(REQUIRES 6.8)
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/vendor/nextkdeAppDemo/shared/qml/CMakeLists.txt")
    message(FATAL_ERROR "Run git submodule update --init --recursive")
endif()
add_subdirectory(vendor/nextkdeAppDemo/shared/qml kos-ui)
qt_add_executable(kmusic src/main.cpp
    src/AudioCache.cpp src/AudioCache.h src/MetadataScanner.cpp src/MetadataScanner.h
    src/MusicDatabase.cpp src/MusicDatabase.h src/MusicTypes.h src/MprisService.cpp src/MprisService.h
    src/PlaybackEngine.cpp src/PlaybackEngine.h src/Transcoder.cpp src/Transcoder.h
    src/LxSourceService.cpp src/LxSourceService.h src/LyricsService.cpp src/LyricsService.h
    src/OnlineMusicProvider.cpp src/OnlineMusicProvider.h src/AccountController.cpp src/AccountController.h src/SubsonicProvider.cpp src/SubsonicProvider.h)
set_source_files_properties(qml/MusicColors.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
qt_add_qml_module(kmusic URI NextKde.Music VERSION 1.0 RESOURCE_PREFIX /qt/qml
    SOURCES src/MusicController.cpp src/MusicController.h src/TrackListModel.cpp src/TrackListModel.h
    QML_FILES qml/SearchHistory.mjs qml/MusicTextField.qml qml/MediaSourcesPage.qml qml/SettingsPage.qml qml/SearchDialog.qml qml/LocalMusicPage.qml qml/PersonalPage.qml qml/UiLanguage.mjs qml/NavigationHomePage.qml qml/LocalFoldersPage.qml qml/SourceConnectionDialog.qml qml/SourceDemoPage.qml qml/MusicSourceCatalog.mjs qml/CollectionList.qml qml/OnlineAlbumPage.qml qml/AccountDialog.qml qml/MusicColors.qml qml/MusicActionButton.qml qml/MusicNavigationButton.qml qml/MusicSelect.qml qml/Main.qml qml/Artwork.qml qml/AlbumTile.qml qml/DiscoveryPage.qml qml/SongsPage.qml qml/PlayerBar.qml qml/WindowChrome.qml qml/NowPlaying.qml qml/OnlinePage.qml)
target_include_directories(kmusic PRIVATE src)
target_link_libraries(kmusic PRIVATE Qt6Keychain::Qt6Keychain PkgConfig::MUSIC_QRENCODE Kos::Ui Kos::UiPlugin Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::QuickDialogs2 Qt6::Concurrent Qt6::DBus Qt6::Network Qt6::Sql PkgConfig::MUSIC_GSTREAMER PkgConfig::MUSIC_TAGLIB)
target_compile_definitions(kmusic PRIVATE MUSIC_VERSION="${PROJECT_VERSION}")
install(TARGETS kmusic RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES data/kmusic.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
install(FILES data/kmusic.svg DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps)

# Ship the generated plain-JavaScript provider: distro Node may lack TypeScript.
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/providers/runtime/helper.js")
    message(FATAL_ERROR "Missing generated provider runtime; regenerate with tools/build-provider-runtime.mjs")
endif()
# No Electron UI, TypeScript support or npm install is needed at runtime.
add_custom_target(kmusic_providers ALL
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/providers ${CMAKE_CURRENT_BINARY_DIR}/providers)
add_dependencies(kmusic kmusic_providers)
install(DIRECTORY providers/ DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/kmusic/providers)

# Explicitly opt-in integration runner. Uses isolated data paths supplied by the runner.
option(KMUSIC_BUILD_LOCAL_TESTS "Build local-library integration tests" OFF)
if(KMUSIC_BUILD_LOCAL_TESTS)
    qt_add_executable(kmusic_local_tests tests/local_music_integration.cpp
        src/MusicController.cpp src/TrackListModel.cpp src/AudioCache.cpp
        src/MetadataScanner.cpp src/MusicDatabase.cpp src/MprisService.cpp
        src/PlaybackEngine.cpp src/Transcoder.cpp src/LxSourceService.cpp
        src/LyricsService.cpp src/OnlineMusicProvider.cpp src/AccountController.cpp src/SubsonicProvider.cpp)
    target_include_directories(kmusic_local_tests PRIVATE src)
    target_link_libraries(kmusic_local_tests PRIVATE Qt6Keychain::Qt6Keychain
        PkgConfig::MUSIC_QRENCODE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Concurrent
        Qt6::DBus Qt6::Network Qt6::Sql PkgConfig::MUSIC_GSTREAMER PkgConfig::MUSIC_TAGLIB)
    target_compile_definitions(kmusic_local_tests PRIVATE MUSIC_VERSION="${PROJECT_VERSION}")
    add_dependencies(kmusic_local_tests kmusic_providers)
endif()

option(KMUSIC_BUILD_SUBSONIC_TESTS "Build isolated media-server integration runner" OFF)
if(KMUSIC_BUILD_SUBSONIC_TESTS)
    qt_add_executable(kmusic_subsonic_tests tests/subsonic_integration.cpp
        src/MusicController.cpp src/TrackListModel.cpp src/AudioCache.cpp
        src/MetadataScanner.cpp src/MusicDatabase.cpp src/MprisService.cpp
        src/PlaybackEngine.cpp src/Transcoder.cpp src/LxSourceService.cpp
        src/LyricsService.cpp src/OnlineMusicProvider.cpp src/AccountController.cpp src/SubsonicProvider.cpp)
    target_include_directories(kmusic_subsonic_tests PRIVATE src)
    target_link_libraries(kmusic_subsonic_tests PRIVATE Qt6Keychain::Qt6Keychain
        PkgConfig::MUSIC_QRENCODE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Concurrent
        Qt6::DBus Qt6::Network Qt6::Sql PkgConfig::MUSIC_GSTREAMER PkgConfig::MUSIC_TAGLIB)
    target_compile_definitions(kmusic_subsonic_tests PRIVATE MUSIC_VERSION="${PROJECT_VERSION}")
    add_dependencies(kmusic_subsonic_tests kmusic_providers)
endif()
option(KMUSIC_TEST_ASAN "Enable address sanitizer for media integration runner" OFF)
if(KMUSIC_BUILD_SUBSONIC_TESTS AND KMUSIC_TEST_ASAN)
    target_compile_options(kmusic_subsonic_tests PRIVATE -fsanitize=address -fno-omit-frame-pointer -g)
    target_link_options(kmusic_subsonic_tests PRIVATE -fsanitize=address)
endif()
