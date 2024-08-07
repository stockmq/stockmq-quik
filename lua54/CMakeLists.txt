﻿# CMakeList.txt : CMake project for lua54

set(LUA_SOURCES
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
add_library (lua54 SHARED ${LUA_SOURCES})
target_compile_definitions(lua54 PRIVATE LUA_BUILD_AS_DLL)

set(LIB_SOURCES
  ../src/stockmq.cpp
  ../src/stockmq.h
)

add_library (stockmq54 SHARED ${LIB_SOURCES})
set_target_properties(stockmq54 PROPERTIES OUTPUT_NAME "stockmq")
target_include_directories(stockmq54 PRIVATE src)
target_link_libraries(stockmq54 PRIVATE lua54)
target_link_libraries(stockmq54 PRIVATE cppzmq cppzmq-static)
target_link_libraries(stockmq54 PRIVATE msgpack-cxx)

set_property(TARGET stockmq54 PROPERTY CXX_STANDARD 20)
set_property(TARGET stockmq54 PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

