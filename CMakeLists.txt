cmake_minimum_required(VERSION 3.21)

project(DirectDesktop
    VERSION 0.6.0
    DESCRIPTION "Custom shell replacement prototype made with DirectUI"
    LANGUAGES CXX RC)

# optional build path. DirectDesktop.sln and the .vcxproj files are still the
# real build and nothing here touches them. this just means you can build
# without visual studio, which also gets clion, ninja and ci working.

if(NOT WIN32)
    message(FATAL_ERROR "DirectDesktop is a win32 shell replacement, windows only.")
endif()

if(NOT MSVC)
    message(FATAL_ERROR
        "msvc only. the sources use backslash separators in #include paths and "
        "msvc-specific pragmas, clang and gcc will not get through them.")
endif()

# DirectDesktop/Include/dui70 is a submodule. it holds the DirectUI headers and
# the stub sources that produce dui70.lib, so without it nothing links. a plain
# clone skips submodules and the resulting errors are a mess to read, so bail
# early with something useful instead.
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/DirectDesktop/Include/dui70/DirectUI/DirectUI.h")
    message(FATAL_ERROR
        "dui70 submodule is missing. run:\n"
        "    git submodule update --init --recursive")
endif()

set(DD_CXX_STANDARD 20 CACHE STRING "c++ standard for the first-party targets (17, 20 or 23)")
set_property(CACHE DD_CXX_STANDARD PROPERTY STRINGS 17 20 23)

# 20 is the default on purpose. the dui70 vcxproj builds at stdcpp20 while the
# four first-party projects sit on msvc's default (14), so DDUI and
# DirectDesktop currently parse DirectUI.h in a different language mode than the
# lib it links against. matching 20 removes that split. 17 is the safe fallback.
# 23 maps to /std:c++latest on msvc and shifts between toolsets, so treat it as
# experimental rather than a target.

set(CMAKE_CXX_STANDARD ${DD_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# everything that ships together goes in bin/. the dui70 and duser stubs
# deliberately do not, see cmake/dui70.cmake for why.
set(DD_BIN_DIR "${CMAKE_BINARY_DIR}/bin/$<CONFIG>")

# from AdditionalDependencies in DDUI.vcxproj and DirectDesktop.vcxproj.
# shlwapi appears twice there, deduped here.
set(DD_SYSTEM_LIBS
    UxTheme
    WindowsCodecs
    gdiplus
    Ole32
    Advapi32
    Shell32
    User32
    Gdi32
    Shlwapi
    dwmapi
    comctl32
    shcore
    wtsapi32
    powrprof)

# shared compile and link setup, lifted from the ItemDefinitionGroup blocks.
function(dd_common target)
    target_compile_definitions(${target} PRIVATE
        UNICODE
        _UNICODE
        _WINDOWS
        "$<$<CONFIG:Debug>:_DEBUG>"
        "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")

    # msbuild defines WIN32 on the Win32 platform only, not x64.
    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        target_compile_definitions(${target} PRIVATE WIN32)
    endif()

    # /W3 = WarningLevel Level3, /permissive- = ConformanceMode, /sdl = SDLCheck.
    #
    # /Zc:wchar_t- is the one worth reading twice. it makes wchar_t a typedef for
    # unsigned short instead of a builtin, which DirectUI's abi expects.
    # DirectDesktop.vcxproj sets it on all four configs, DDUI.vcxproj only on
    # Release|x64, and ModernShellAbout never sets it at all. those modules pass
    # types across dll boundaries while including the same DirectUI headers, so
    # that split is an abi mismatch waiting to happen and it goes on everything
    # here. worth knowing it also puts us at odds with msvc's stl, which wants
    # native wchar_t, so if <string> or <regex> start throwing link errors at a
    # higher standard this flag is the first suspect.
    target_compile_options(${target} PRIVATE
        /W3
        /permissive-
        /sdl
        /Zc:wchar_t-
        "$<$<NOT:$<CONFIG:Debug>>:/Gy;/Oi;/GL>")

    # /GL above needs /LTCG here. the rest is EnableCOMDATFolding and
    # OptimizeReferences from the release blocks.
    target_link_options(${target} PRIVATE
        "$<$<NOT:$<CONFIG:Debug>>:/LTCG;/OPT:REF;/OPT:ICF>")
endfunction()

include(cmake/dui70.cmake)

add_subdirectory(DDUI)
add_subdirectory(DirectDesktop)
add_subdirectory(ModernShellAbout)
add_subdirectory(ShutDownWindows)

message(STATUS "DirectDesktop: c++${DD_CXX_STANDARD}, output in ${CMAKE_BINARY_DIR}/bin")
