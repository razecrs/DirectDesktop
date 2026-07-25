# ModernShellAbout.dll. only pulls windows.h, no DirectUI, so no dui70 linkage.
# ConfigurationType in the vcxproj is DynamicLibrary, it is not an exe.

add_library(ModernShellAbout SHARED
    ModernShellAbout.cpp
    ModernShellAbout.rc)

dd_common(ModernShellAbout)

target_precompile_headers(ModernShellAbout PRIVATE pch.h)

target_compile_definitions(ModernShellAbout PRIVATE
    MODERNSHELLABOUT_EXPORTS
    _USRDLL)

target_include_directories(ModernShellAbout PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}")

# no target_link_libraries, the vcxproj declares no AdditionalDependencies and
# msvc's default libs already cover what windows.h needs.

set_target_properties(ModernShellAbout PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${DD_BIN_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${DD_BIN_DIR}"
    ARCHIVE_OUTPUT_DIRECTORY "${DD_BIN_DIR}")
