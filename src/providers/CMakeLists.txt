add_library(kmusic_provider_core STATIC
    Request.cpp
    HttpTransport.cpp HttpTransport.h
    bilibili/BilibiliDetail.cpp bilibili/BilibiliDetail.h)
target_include_directories(kmusic_provider_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(kmusic_provider_core PUBLIC Qt6::Core Qt6::Network)
