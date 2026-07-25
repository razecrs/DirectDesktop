# DirectDesktop.exe. sources match the ClCompile list in DirectDesktop.vcxproj,
# minus pch.cpp which cmake handles itself.

add_executable(DirectDesktop WIN32
    DirectDesktop.cpp
    backend/ContextMenus.cpp
    backend/DirectoryHelper.cpp
    backend/DragAndDrop.cpp
    backend/Logger.cpp
    backend/RenameCore.cpp
    backend/SettingsHelper.cpp
    ui/EditMode.cpp
    ui/SearchPage.cpp
    ui/ShutdownDialog.cpp
    ui/Subview.cpp
    DirectDesktop.rc
    DirectDesktop.manifest)

dd_common(DirectDesktop)

target_precompile_headers(DirectDesktop PRIVATE pch.h)

target_include_directories(DirectDesktop PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/backend"
    "${CMAKE_CURRENT_SOURCE_DIR}/ui")

# HAS_SEARCH is intentionally not defined. DirectDesktop.vcxproj sets it under
# Release|x64 but nothing in the tree reads it, and the Everything integration it
# looks like it was meant to gate is loaded at runtime anyway
# (ui/SearchPage.cpp does LoadLibraryW(L"Everything64.dll")).

# DDUI first, it pulls dui70 and duser through transitively.
target_link_libraries(DirectDesktop PRIVATE
    DDUI
    ${DD_SYSTEM_LIBS})

set_target_properties(DirectDesktop PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${DD_BIN_DIR}")

# DirectDesktop.cpp includes "build_timestamp.h", which is generated rather than
# committed. the .sln does it with a powershell pre-build event; doing the same
# through cmake -P keeps this build free of a powershell dependency and works the
# same under ninja, where PRE_BUILD steps do not exist.
#
# ALL plus no OUTPUT means it re-runs every build, which is the point, the
# timestamp is meant to be the time you built it.
add_custom_target(dd_build_timestamp ALL
    COMMAND "${CMAKE_COMMAND}"
        -D "DD_TIMESTAMP_OUT=${CMAKE_CURRENT_SOURCE_DIR}/build_timestamp.h"
        -P "${CMAKE_SOURCE_DIR}/cmake/build_timestamp.cmake"
    BYPRODUCTS "${CMAKE_CURRENT_SOURCE_DIR}/build_timestamp.h"
    COMMENT "generating build_timestamp.h")

add_dependencies(DirectDesktop dd_build_timestamp)
