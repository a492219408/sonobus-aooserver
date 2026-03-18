# CMake build configuration for aooserver on Windows
# Toolchain: x86_64 MinGW-w64 UCRT posix seh
# Generator:  Ninja
#
# Quick-start (from this directory):
#
#   Debug build:
#     cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=toolchain-mingw-ucrt-x86_64.cmake \
#           -DCMAKE_BUILD_TYPE=Debug ../..
#     ninja
#
#   Release build:
#     cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=toolchain-mingw-ucrt-x86_64.cmake \
#           -DCMAKE_BUILD_TYPE=Release ../..
#     ninja
#
# The resulting binary will be placed in the build directory as aooserver.exe.

cmake_minimum_required(VERSION 3.15)

project(aooserver VERSION 1.0.0 LANGUAGES C CXX)

# ---------------------------------------------------------------------------
# Language standard
# ---------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ---------------------------------------------------------------------------
# Build type
# ---------------------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type (Debug|Release)" FORCE)
endif()
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")

# ---------------------------------------------------------------------------
# Source files  (mirrors the Linux Makefile object list exactly)
# ---------------------------------------------------------------------------

# AOO library
set(AOO_SOURCES
    ../../deps/aoo/lib/src/client.cpp
    ../../deps/aoo/lib/src/codec_pcm.cpp
    ../../deps/aoo/lib/src/common.cpp
    ../../deps/aoo/lib/src/net_utils.cpp
    ../../deps/aoo/lib/src/server.cpp
    ../../deps/aoo/lib/src/sink.cpp
    ../../deps/aoo/lib/src/source.cpp
    ../../deps/aoo/lib/src/sync.cpp
    ../../deps/aoo/lib/src/time.cpp
)

# OSCpack
set(OSCPACK_SOURCES
    ../../deps/aoo/deps/oscpack/osc/OscOutboundPacketStream.cpp
    ../../deps/aoo/deps/oscpack/osc/OscPrintReceivedElements.cpp
    ../../deps/aoo/deps/oscpack/osc/OscReceivedElements.cpp
    ../../deps/aoo/deps/oscpack/osc/OscTypes.cpp
)

# MD5
set(MD5_SOURCES
    ../../deps/aoo/deps/md5/md5.c
)

# JUCE amalgamation units
set(JUCE_SOURCES
    ../../JuceLibraryCode/include_juce_audio_basics.cpp
    ../../JuceLibraryCode/include_juce_audio_formats.cpp
    ../../JuceLibraryCode/include_juce_core.cpp
    ../../JuceLibraryCode/include_juce_cryptography.cpp
    ../../JuceLibraryCode/include_juce_data_structures.cpp
    ../../JuceLibraryCode/include_juce_events.cpp
)

# Application
set(APP_SOURCES
    ../../Source/Main.cpp
)

# ---------------------------------------------------------------------------
# Target
# ---------------------------------------------------------------------------
add_executable(aooserver
    ${AOO_SOURCES}
    ${OSCPACK_SOURCES}
    ${MD5_SOURCES}
    ${JUCE_SOURCES}
    ${APP_SOURCES}
)

# ---------------------------------------------------------------------------
# Include directories
# ---------------------------------------------------------------------------
target_include_directories(aooserver PRIVATE
    ../../JuceLibraryCode
    ../../JuceLibraryCode/modules
    ../../deps/aoo/lib
    ../../deps/aoo/deps
)

# ---------------------------------------------------------------------------
# Compile definitions (common)
# ---------------------------------------------------------------------------
target_compile_definitions(aooserver PRIVATE
    # Platform
    WINDOWS=1

    # Build AOO as static (avoid dllimport)
    AOO_STATIC=1

    # Disable Opus codec (not used)
    USE_CODEC_OPUS=0

    # Disable audio I/O APIs not needed for a headless server
    JUCE_WASAPI=0
    JUCE_DIRECTSOUND=0

    # Disable libcurl; JUCE uses WinINet/WinHTTP on Windows
    JUCE_USE_CURL=0

    # Application version
    JUCE_APP_VERSION=1.0.0
    JUCE_APP_VERSION_HEX=0x10000

    # Disable unused JUCE plug-in build targets
    JucePlugin_Build_VST=0
    JucePlugin_Build_VST3=0
    JucePlugin_Build_AU=0
    JucePlugin_Build_AUv3=0
    JucePlugin_Build_AAX=0
    JucePlugin_Build_Standalone=0
    JucePlugin_Build_Unity=0
    JucePlugin_Build_LV2=0
)

# ---------------------------------------------------------------------------
# Configuration-specific definitions and flags
# ---------------------------------------------------------------------------
target_compile_definitions(aooserver PRIVATE
    $<$<CONFIG:Debug>:DEBUG=1>
    $<$<CONFIG:Debug>:_DEBUG=1>
    $<$<CONFIG:Debug>:LOGLEVEL=3>
    $<$<CONFIG:Release>:NDEBUG=1>
)

target_compile_options(aooserver PRIVATE
    $<$<CONFIG:Debug>:-O0 -g -ggdb>
    $<$<CONFIG:Release>:-O3>
    -fvisibility=hidden
)

# ---------------------------------------------------------------------------
# Linker flags
# ---------------------------------------------------------------------------
# Link statically against the MinGW runtime so the binary is self-contained.
target_link_options(aooserver PRIVATE
    $<$<CONFIG:Release>:-s>
    -static
    -static-libgcc
    -static-libstdc++
)

# ---------------------------------------------------------------------------
# Windows libraries required by JUCE core & networking
# ---------------------------------------------------------------------------
target_link_libraries(aooserver PRIVATE
    ws2_32      # Windows Sockets (networking)
    winmm       # Windows Multimedia (timers)
    version     # Version information
    shlwapi     # Shell Lightweight Utility APIs
    advapi32    # Advanced Windows APIs
    comdlg32    # Common Dialogs
    comctl32    # Common Controls
    imm32       # Input Method Manager
    kernel32    # Core Windows
    ole32       # OLE
    oleaut32    # OLE Automation
    shell32     # Windows Shell
    user32      # User Interface
    uuid        # UUID library
    wininet     # WinINet (HTTP/FTP for JUCE networking)
)

# ---------------------------------------------------------------------------
# Installation
# ---------------------------------------------------------------------------
install(TARGETS aooserver RUNTIME DESTINATION bin)
