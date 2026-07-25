# DDUI.dll, the control library. sources match the ClCompile list in DDUI.vcxproj.
# pch.cpp is left out on purpose, cmake generates its own pch translation unit.

add_library(DDUI SHARED
    common.cpp
    DDControls.cpp
    SettingsHelper.cpp
    coreui/AccentColorHelper.cpp
    coreui/AnimationHelper.cpp
    coreui/BitmapHelper.cpp
    coreui/ColorHelper.cpp
    coreui/StyleModifier.cpp
    DDUI.rc)

dd_common(DDUI)

target_precompile_headers(DDUI PRIVATE pch.h)

target_compile_definitions(DDUI PRIVATE
    DDUI_EXPORTS
    _USRDLL)

# the sources reach the DirectUI headers with relative backslash paths like
# "..\DirectDesktop\Include\dui70\DirectUI\DirectUI.h", which resolve against the
# including file, so this is mostly belt and braces.
target_include_directories(DDUI PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/coreui")

# note this is wired for every config. DDUI.vcxproj only declares its
# AdditionalDependencies under Release|x64, so debug and Win32 cannot link there
# at all. no reason to reproduce that here.
target_link_libraries(DDUI PRIVATE
    dui70
    duser
    ${DD_SYSTEM_LIBS})

set_target_properties(DDUI PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${DD_BIN_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${DD_BIN_DIR}"
    ARCHIVE_OUTPUT_DIRECTORY "${DD_BIN_DIR}")
