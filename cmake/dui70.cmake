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
#
# these two are not our code, so the flags below copy DirectUI.vcxproj and
# DUser.vcxproj rather than going through dd_common. they are not configured the
# same as each other either: DUser sets stdcpp20, ConformanceMode and SDLCheck,
# DirectUI sets none of the three and adds /utf-8. worth not "tidying" that up.

set(DUI70_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/DirectDesktop/Include/dui70")
set(DD_STUB_DIR "${CMAKE_BINARY_DIR}/stubs/$<CONFIG>")

# shared bits: same optimisation set as the release blocks, same wchar_t handling
# as everything that touches DirectUI, and the _EXPORTS macro the headers switch
# on. that last one has to be spelled out because cmake would otherwise define
# dui70_EXPORTS / duser_EXPORTS off the target name, the headers want
# DIRECTUI_EXPORTS / DUSER_EXPORTS, and getting it wrong turns every function in
# the stub into "C2491: definition of dllimport function not allowed".
function(dd_stub_common target exports_macro)
    target_compile_definitions(${target} PRIVATE
        UNICODE
        _UNICODE
        _WINDOWS
        _USRDLL
        _WINDLL
        ${exports_macro}
        "$<$<CONFIG:Debug>:_DEBUG>"
        "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")

    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        target_compile_definitions(${target} PRIVATE WIN32)
    endif()

    target_compile_options(${target} PRIVATE
        /W3
        /Zc:wchar_t-
        "$<$<NOT:$<CONFIG:Debug>>:/Gy;/Oi;/GL>")

    target_link_options(${target} PRIVATE
        "$<$<NOT:$<CONFIG:Debug>>:/LTCG;/OPT:REF;/OPT:ICF>")

    set_target_properties(${target} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${DD_STUB_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${DD_STUB_DIR}"
        ARCHIVE_OUTPUT_DIRECTORY "${DD_STUB_DIR}")
endfunction()

# DirectUI.def is what actually decides the exported symbols, the .cpp just
# gives the linker bodies to hang them on.
add_library(dui70 SHARED
    "${DUI70_ROOT}/DirectUI/DirectUI.cpp"
    "${DUI70_ROOT}/DirectUI/DirectUI.def")

# TargetName in DirectUI.vcxproj is dui70, not DirectUI, and DDUI links by that
# name so it has to stay.
set_target_properties(dui70 PROPERTIES OUTPUT_NAME dui70)

dd_stub_common(dui70 DIRECTUI_EXPORTS)

# no /permissive-, no /sdl and no /std here, DirectUI.vcxproj sets none of them
# and the file does not survive /permissive-. /utf-8 is in its command line.
target_compile_options(dui70 PRIVATE /utf-8)

# AdditionalIncludeDirectories in DirectUI.vcxproj adds ..\DUser. PUBLIC because
# anything including DirectUI.h needs the same headers reachable.
target_include_directories(dui70 PUBLIC
    "${DUI70_ROOT}"
    "${DUI70_ROOT}/DirectUI"
    "${DUI70_ROOT}/DUser")

add_library(duser SHARED
    "${DUI70_ROOT}/DUser/DUser.cpp")

# no .def here, DUser.cpp exports through its DUSER_API macro instead.
set_target_properties(duser PROPERTIES OUTPUT_NAME duser)

dd_stub_common(duser DUSER_EXPORTS)

# DUser.vcxproj is the one project in the submodule that does set all three.
set_target_properties(duser PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON)
target_compile_options(duser PRIVATE /permissive- /sdl)

target_include_directories(duser PUBLIC
    "${DUI70_ROOT}"
    "${DUI70_ROOT}/DUser")
