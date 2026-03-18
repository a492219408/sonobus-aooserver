# Toolchain file for x86_64 MinGW-w64 UCRT posix seh
#
# This toolchain targets Windows x86_64 using the MinGW-w64 toolchain with:
#   - UCRT (Universal C Runtime) as the C runtime
#   - posix threading model
#   - SEH (Structured Exception Handling) exception model
#
# Usage (cross-compiling from Linux, from the repo root):
#   cmake -B build -G Ninja \
#         -DCMAKE_TOOLCHAIN_FILE=toolchain-mingw-ucrt-x86_64.cmake \
#         -DCMAKE_BUILD_TYPE=Release
#   cmake --build build
#
# Usage (native Windows with MinGW in PATH, from the repo root):
#   cmake -B build -G Ninja \
#         -DCMAKE_TOOLCHAIN_FILE=toolchain-mingw-ucrt-x86_64.cmake \
#         -DCMAKE_BUILD_TYPE=Release
#   cmake --build build

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Detect whether we are cross-compiling from Linux/macOS or building natively on Windows.
# On Linux the cross-compiler binaries use the "x86_64-w64-mingw32" prefix.
# On native Windows the MinGW-w64 UCRT binaries are typically available without a prefix.
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    # Native Windows: prefer UCRT-specific names to avoid picking up Cygwin or MSYS2's default gcc
    find_program(MINGW_C_COMPILER   NAMES x86_64-w64-mingw32ucrt-gcc x86_64-w64-mingw32-gcc gcc)
    find_program(MINGW_CXX_COMPILER NAMES x86_64-w64-mingw32ucrt-g++ x86_64-w64-mingw32-g++ g++)
    find_program(MINGW_RC_COMPILER  NAMES x86_64-w64-mingw32ucrt-windres x86_64-w64-mingw32-windres windres)
else()
    # Cross-compilation from Linux/macOS
    find_program(MINGW_C_COMPILER   NAMES x86_64-w64-mingw32ucrt-gcc x86_64-w64-mingw32-gcc)
    find_program(MINGW_CXX_COMPILER NAMES x86_64-w64-mingw32ucrt-g++ x86_64-w64-mingw32-g++)
    find_program(MINGW_RC_COMPILER  NAMES x86_64-w64-mingw32ucrt-windres x86_64-w64-mingw32-windres)
endif()

if(NOT MINGW_C_COMPILER)
    message(FATAL_ERROR
        "Could not find the MinGW-w64 C compiler (x86_64-w64-mingw32-gcc).\n"
        "On Debian/Ubuntu install it with: sudo apt install mingw-w64\n"
        "On MSYS2/Windows install it with: pacman -S mingw-w64-ucrt-x86_64-gcc")
endif()
if(NOT MINGW_CXX_COMPILER)
    message(FATAL_ERROR
        "Could not find the MinGW-w64 C++ compiler (x86_64-w64-mingw32-g++).\n"
        "On Debian/Ubuntu install it with: sudo apt install mingw-w64\n"
        "On MSYS2/Windows install it with: pacman -S mingw-w64-ucrt-x86_64-gcc")
endif()

set(CMAKE_C_COMPILER   "${MINGW_C_COMPILER}"   CACHE FILEPATH "C compiler")
set(CMAKE_CXX_COMPILER "${MINGW_CXX_COMPILER}" CACHE FILEPATH "C++ compiler")
if(MINGW_RC_COMPILER)
    set(CMAKE_RC_COMPILER  "${MINGW_RC_COMPILER}"  CACHE FILEPATH "RC compiler")
endif()

# Sysroot for cross-compilation (ignored on native Windows)
if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    foreach(_root
            /usr/x86_64-w64-mingw32
            /usr/lib/mxe/usr/x86_64-w64-mingw32.shared
            /opt/x86_64-w64-mingw32)
        if(EXISTS "${_root}")
            set(CMAKE_FIND_ROOT_PATH "${_root}" CACHE PATH "MinGW sysroot")
            break()
        endif()
    endforeach()
endif()

# Adjust CMake's find_* behaviour for cross-compilation
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
