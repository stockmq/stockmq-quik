// LuaOverMQ.h : Header file for your target.

#pragma once

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers

// Windows Header Files
#include <windows.h>

// STL
#include <string>
#include <chrono>
#include <format>

// MsgPack
#include <msgpack.hpp>

// ZeroMQ
#include <zmq.hpp>

// Lua
#define LUA_LIB
#define LUA_BUILD_AS_DLL

extern "C" {
#include <lauxlib.h>
#include <lualib.h>
}