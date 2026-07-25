# dui70 and duser, built from the submodule the same way the .sln builds them.
#
# read this before changing the output paths. both of these are stub dlls: every
# function body in DirectUI.cpp and DUser.cpp is STUB_ZERO or STUB_VOID, so they
# do nothing at runtime. they exist purely so the linker has dui70.lib and
# duser.lib to bind against, and at runtime the app picks up the real dui70.dll
# that already ships with windows.
#
# which means: if a stub dll ends up sitting next to DirectDesktop.exe, windows
# resolves the import to the stub instead of the system dll, every DirectUI call
# returns 0, and you get a build that links clean and does nothing. that failure
# is silent and it is much worse than a link error. the .sln avoids it by putting
# them under build/<cfg>-<plat>/DirectUI/ and build/<cfg>-<plat>/DUser/ while the
# exe goes in build/<cfg>-<plat>/DirectDesktop/, so we keep the same separation
# with a stubs/ directory well away from bin/.

set(DUI70_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/DirectDesktop/Include/dui70")
set(DD_STUB_DIR "${CMAKE_BINARY_DIR}/stubs/$<CONFIG>")

# DirectUI.def is what actually decides the exported symbols, the .cpp just
# gives the linker bodies to hang them on.
add_library(dui70 SHARED
    "${DUI70_ROOT}/DirectUI/DirectUI.cpp"
    "${DUI70_ROOT}/DirectUI/DirectUI.def")

# TargetName in DirectUI.vcxproj is dui70, not DirectUI, and DDUI links by that
# name so it has to stay.
set_target_properties(dui70 PROPERTIES
    OUTPUT_NAME dui70
    RUNTIME_OUTPUT_DIRECTORY "${DD_STUB_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${DD_STUB_DIR}"
    ARCHIVE_OUTPUT_DIRECTORY "${DD_STUB_DIR}")

# AdditionalIncludeDirectories in DirectUI.vcxproj adds ..\DUser. PUBLIC because
# anything including DirectUI.h needs the same reachable headers.
target_include_directories(dui70 PUBLIC
    "${DUI70_ROOT}"
    "${DUI70_ROOT}/DirectUI"
    "${DUI70_ROOT}/DUser")

add_library(duser SHARED
    "${DUI70_ROOT}/DUser/DUser.cpp")

# no .def here, DUser.cpp exports through its DUSER_API macro instead.
set_target_properties(duser PROPERTIES
    OUTPUT_NAME duser
    RUNTIME_OUTPUT_DIRECTORY "${DD_STUB_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${DD_STUB_DIR}"
    ARCHIVE_OUTPUT_DIRECTORY "${DD_STUB_DIR}")

target_include_directories(duser PUBLIC
    "${DUI70_ROOT}"
    "${DUI70_ROOT}/DUser")

# the submodule's own vcxproj files build at stdcpp20, so pin these two there
# regardless of what DD_CXX_STANDARD is set to. it is not our code to modernise.
foreach(stub dui70 duser)
    set_target_properties(${stub} PROPERTIES
        CXX_STANDARD 20
        CXX_STANDARD_REQUIRED ON)
    dd_common(${stub})
endforeach()
