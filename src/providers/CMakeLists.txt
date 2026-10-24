add_library(kmusic_provider_core STATIC
    Request.cpp
    bilibili/BilibiliSession.cpp bilibili/BilibiliAccount.cpp bilibili/BilibiliLibrary.cpp
    bilibili/WbiSigner.cpp bilibili/BilibiliResponse.cpp bilibili/BilibiliApi.cpp
    bilibili/BilibiliSearch.cpp bilibili/BilibiliPlaybackResolver.cpp
    HttpTransport.cpp HttpTransport.h
    bilibili/BilibiliDetail.cpp bilibili/BilibiliDetail.h)
target_include_directories(kmusic_provider_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(kmusic_provider_core PUBLIC Qt6::Core Qt6::Network)
