# generates DirectDesktop/build_timestamp.h, same two macros and same format as
# DirectDesktop/build_timestamp.ps1 produces, so both build paths agree.
#
# run as: cmake -D DD_TIMESTAMP_OUT=<path> -P cmake/build_timestamp.cmake

if(NOT DEFINED DD_TIMESTAMP_OUT)
    message(FATAL_ERROR "DD_TIMESTAMP_OUT was not set")
endif()

string(TIMESTAMP DD_BUILD_DATE "%Y-%m-%d" UTC)
string(TIMESTAMP DD_BUILD_TIMESTAMP "%y%m%d-%H%M" UTC)

set(DD_CONTENT
"#define BUILD_DATE L\"${DD_BUILD_DATE}\"
#define BUILD_TIMESTAMP L\"${DD_BUILD_TIMESTAMP}\"
")

# only write when it actually changed, otherwise every build touches the header
# and drags DirectDesktop.cpp through a rebuild with it. the ps1 script rewrites
# unconditionally, which is why msbuild recompiles it every time.
set(DD_EXISTING "")
if(EXISTS "${DD_TIMESTAMP_OUT}")
    file(READ "${DD_TIMESTAMP_OUT}" DD_EXISTING)
endif()

if(NOT DD_EXISTING STREQUAL DD_CONTENT)
    file(WRITE "${DD_TIMESTAMP_OUT}" "${DD_CONTENT}")
endif()
