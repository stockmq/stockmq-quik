# CMakeList.txt : CMake project for lua54, include source and define
# project specific logic here.
#

set(SOURCE_LIB
  src/lapi.c
  src/lauxlib.c
  src/lbaselib.c
  src/lcode.c
  src/lcorolib.c
  src/lctype.c
  src/ldblib.c
  src/ldebug.c
  src/ldo.c
  src/ldump.c
  src/lfunc.c
  src/lgc.c
  src/linit.c
  src/liolib.c
  src/llex.c
  src/lmathlib.c
  src/lmem.c
  src/loadlib.c
  src/lobject.c
  src/lopcodes.c
  src/loslib.c
  src/lparser.c
  src/lstate.c
  src/lstring.c
  src/lstrlib.c
  src/ltable.c
  src/ltablib.c
  src/ltests.c
  src/ltm.c
  src/lundump.c
  src/lutf8lib.c
  src/lvm.c
  src/lzio.c
)
add_library (lua54 SHARED ${SOURCE_LIB})
target_compile_definitions(lua54 PRIVATE LUA_BUILD_AS_DLL)

add_library (LuaOverMQ54 SHARED "../src/LuaOverMQ.cpp" "../src/LuaOverMQ.h")
set_target_properties(LuaOverMQ54 PROPERTIES OUTPUT_NAME "LuaOverMQ")
target_include_directories(LuaOverMQ54 PRIVATE src)
target_link_libraries(LuaOverMQ54 PRIVATE lua54)
target_link_libraries(LuaOverMQ54 PRIVATE cppzmq cppzmq-static)
target_link_libraries(LuaOverMQ54 PRIVATE msgpack-cxx)

if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET lua54 PROPERTY CXX_STANDARD 20)
  set_property(TARGET LuaOverMQ54 PROPERTY CXX_STANDARD 20)
endif()
