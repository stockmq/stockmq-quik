# CMakeList.txt : CMake project for LuaOverMQ, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

# Enable Hot Reload for MSVC compilers if supported.
if (POLICY CMP0141)
  cmake_policy(SET CMP0141 NEW)
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<IF:$<AND:$<C_COMPILER_ID:MSVC>,$<CXX_COMPILER_ID:MSVC>>,$<$<CONFIG:Debug,RelWithDebInfo>:EditAndContinue>,$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>>")
endif()

project ("LuaOverMQ")

add_subdirectory("lua53")
add_subdirectory("lua54")

set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MT")

set(SOURCE_LIB "LuaOverMQ.cpp" "LuaOverMQ.h")

find_package(cppzmq CONFIG REQUIRED)
find_package(msgpack-cxx CONFIG REQUIRED)

# Add source to this project's executable.
add_library (LuaOverMQ53 SHARED ${SOURCE_LIB})
target_include_directories(LuaOverMQ53 PRIVATE lua54)
target_link_libraries(LuaOverMQ53 PRIVATE lua54)
target_link_libraries(LuaOverMQ53 PRIVATE cppzmq cppzmq-static)
target_link_libraries(LuaOverMQ53 PRIVATE msgpack-cxx)

add_library (LuaOverMQ54 SHARED ${SOURCE_LIB})
target_include_directories(LuaOverMQ54 PRIVATE lua54)
target_link_libraries(LuaOverMQ54 PRIVATE lua54)
target_link_libraries(LuaOverMQ54 PRIVATE cppzmq cppzmq-static)
target_link_libraries(LuaOverMQ54 PRIVATE msgpack-cxx)


if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET LuaOverMQ53 PROPERTY CXX_STANDARD 20)
  set_property(TARGET LuaOverMQ54 PROPERTY CXX_STANDARD 20)
endif()

