# ShutDownWindows.dll. same deal as ModernShellAbout, windows.h only.
# there is a resource.h in here but no .rc to go with it, so nothing to compile.

add_library(ShutDownWindows SHARED
    ShutDownWindows.cpp)

dd_common(ShutDownWindows)

target_precompile_headers(ShutDownWindows PRIVATE pch.h)

# DLL_EXPORT is not defined here even though the vcxproj sets it under
# Release|x64. nothing in the tree reads it, same story as HAS_SEARCH.
target_compile_definitions(ShutDownWindows PRIVATE
    SHUTDOWNWINDOWS_EXPORTS
    _USRDLL)

target_include_directories(ShutDownWindows PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}")

set_target_properties(ShutDownWindows PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${DD_BIN_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${DD_BIN_DIR}"
    ARCHIVE_OUTPUT_DIRECTORY "${DD_BIN_DIR}")
