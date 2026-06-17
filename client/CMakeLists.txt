cmake_minimum_required(VERSION 3.16)

project(Tortu VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(QT NAMES Qt6 REQUIRED COMPONENTS Gui Qml Multimedia Network)
find_package(Qt6 REQUIRED COMPONENTS Gui Qml Multimedia Network)

qt_add_executable(Tortu
    main.cpp
    networkmanager.h networkmanager.cpp
    audioplayer.h audioplayer.cpp
)
if(APPLE)
    target_sources(Tortu PRIVATE ios_helper.h ios_helper.mm)
endif()
if(ANDROID)
    target_sources(Tortu PRIVATE android_helper.h android_helper.cpp)
endif()
set_target_properties(Tortu PROPERTIES OUTPUT_NAME "tortu")
if(APPLE)
    set_target_properties(Tortu PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "Tortu"
        MACOSX_BUNDLE_GUI_IDENTIFIER "cyou.tortu.client"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0.0"
        MACOSX_BUNDLE_BUNDLE_VERSION "1.0.0"
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
    )
endif()
if(ANDROID)
    set_target_properties(Tortu PROPERTIES
        QT_ANDROID_MIN_SDK_VERSION 26
        QT_ANDROID_TARGET_SDK_VERSION 34
        QT_ANDROID_COMPILE_SDK_VERSION 34
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android-sources"
    )
endif()

qt_add_qml_module(Tortu
    URI Tortu
    VERSION 1.0
    QML_FILES
        main.qml
        LoginScreen.qml
        MainScreen.qml
        UploadDialog.qml
        TrackRow.qml
    RESOURCES
        icons/home.svg
        icons/search.svg
        icons/library.svg
        icons/heart.svg
        icons/heart-filled.svg
        icons/heart-filled-white.svg
        icons/upload.svg
        icons/play.svg
        icons/pause.svg
        icons/play-black.svg
        icons/pause-black.svg
        icons/skip-next.svg
        icons/skip-prev.svg
        icons/shuffle.svg
        icons/repeat.svg
        icons/volume-high.svg
        icons/volume-medium.svg
        icons/volume-mute.svg
        icons/lyrics.svg
        icons/close.svg
        icons/user.svg
        icons/logo.svg
)

target_link_libraries(Tortu PRIVATE
    Qt6::Gui
    Qt6::Qml
    Qt6::Multimedia
    Qt6::Network
)
if(APPLE)
    target_link_libraries(Tortu PRIVATE "-framework MediaPlayer" "-framework AVFoundation")
endif()

# Installation Rules for Packaging
install(TARGETS Tortu DESTINATION bin)
install(FILES tortu.desktop DESTINATION share/applications)
install(FILES icons/logo.svg DESTINATION share/icons/hicolor/scalable/apps RENAME tortu.svg)

# CPack Configuration
set(CPACK_PACKAGE_NAME "tortu")
set(CPACK_PACKAGE_VENDOR "Antigravity")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Listen, Share, Search")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_CONTACT "antigravity@example.com")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Antigravity team <antigravity@example.com>")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libqt6gui6, libqt6qml6, libqt6multimedia6, libqt6network6, libqt6svg6")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
set(CPACK_RPM_PACKAGE_REQUIRES "qt6-qtbase-gui, qt6-qtdeclarative, qt6-qtmultimedia, qt6-qtsvg")

# Specify generators
set(CPACK_GENERATOR "DEB;RPM")

include(CPack)

