/*
 * This file is part of the StockMQ distribution (https://github.com/StockMQ).
 * Copyright (c) 2022-2024 Alexander Nusov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#include "stockmq.h"

constexpr auto METATABLE = "luaL_stockmq";
constexpr auto STOCKMQ = "stockmq";
constexpr auto STATUS_ERROR = "ERROR";
constexpr auto STATUS_OK = "OK";

// String Utils
std::string wcs_to_mbs(const std::wstring& wstr, UINT page) {
	auto count = WideCharToMultiByte(page, 0, wstr.c_str(), static_cast<int>(wstr.length()), NULL, 0, NULL, NULL);
	auto str = std::string(count, 0);
	WideCharToMultiByte(page, 0, wstr.c_str(), -1, &str[0], count, NULL, NULL);
	return str;
}

std::wstring mbs_to_wcs(const std::string& str, UINT page) {
	auto count = MultiByteToWideChar(page, 0, str.c_str(), static_cast<int>(str.length()), NULL, 0);
	auto wstr = std::wstring(count, 0);
	MultiByteToWideChar(page, 0, str.c_str(), static_cast<int>(str.length()), &wstr[0], count);
	return wstr;
}

std::string utf8_to_ansi(const std::string& str) {
	return wcs_to_mbs(mbs_to_wcs(str, CP_UTF8), CP_ACP);
}

std::string ansi_to_utf8(const std::string& str) {
	return wcs_to_mbs(mbs_to_wcs(str, CP_ACP), CP_UTF8);
}

// Stack Utils
int stack_table_count(lua_State* L, int t) {
	lua_pushnil(L);
	auto count = 0;
	while (lua_next(L, t) != 0) {
		lua_pop(L, 1);
		count++;
	}
	return count;
}

void stack_push(lua_State* L, msgpack::object& obj) {
	switch (obj.type) {
	case msgpack::type::STR:
		lua_pushstring(L, utf8_to_ansi(obj.as<std::string>()).c_str());
		break;
	case msgpack::type::BOOLEAN:
		lua_pushboolean(L, obj.via.boolean);
		break;
	case msgpack::type::NIL:
		lua_pushnil(L);
		break;
	case msgpack::type::POSITIVE_INTEGER:
		lua_pushinteger(L, static_cast<lua_Integer>(obj.via.i64));
		break;
	case msgpack::type::NEGATIVE_INTEGER:
		lua_pushinteger(L, static_cast<lua_Integer>(obj.via.i64));
		break;
	case msgpack::type::FLOAT32:
		lua_pushnumber(L, static_cast<lua_Number>(obj.via.f64));
		break;
	case msgpack::type::FLOAT64:
		lua_pushnumber(L, static_cast<lua_Number>(obj.via.f64));
		break;
	case msgpack::type::ARRAY:
		lua_newtable(L);
		for (auto i = 0u; i < obj.via.array.size; i++) {
			lua_pushinteger(L, static_cast<lua_Integer>(i) + 1);
			stack_push(L, obj.via.array.ptr[i]);
			lua_settable(L, -3);
		}
		break;
	case msgpack::type::MAP:
		lua_newtable(L);
		for (auto i = 0u; i < obj.via.map.size; i++) {
			stack_push(L, obj.via.map.ptr[i].key);
			stack_push(L, obj.via.map.ptr[i].val);
			lua_settable(L, -3);
		}
	}
}

void stack_pack(msgpack::packer<msgpack::sbuffer>& pk, lua_State* L, int i) {
	switch (lua_type(L, i)) {
	case LUA_TNIL:
		pk.pack_nil();
		break;
	case LUA_TBOOLEAN:
		pk.pack(static_cast<bool>(lua_toboolean(L, i)));
		break;
	case LUA_TNUMBER:
		if (lua_isinteger(L, i)) {
			pk.pack(lua_tointeger(L, i));
		}
		else {
			pk.pack(lua_tonumber(L, i));
		}
		break;
	case LUA_TSTRING:
		pk.pack(ansi_to_utf8(lua_tostring(L, i)));
		break;
	case LUA_TTABLE:
		pk.pack_map(stack_table_count(L, i));
		lua_pushnil(L);
		while (lua_next(L, i)) {
			stack_pack(pk, L, -2);
			stack_pack(pk, L, lua_gettop(L));
			lua_pop(L, 1);
		}
		break;
	default:
		pk.pack_nil();
		break;
	}
}

// StockMQ
struct StockMQ {
	zmq::socket_t* zmq_skt;
	zmq::context_t* zmq_ctx;
	int zmq_err;
};

StockMQ* stockmq_check(lua_State* L, int n) {
	return *(StockMQ**)luaL_checkudata(L, n, METATABLE);
}

void send_multipart(zmq::socket_t* zmq_skt, const std::string& header, const msgpack::sbuffer& buffer) {
	zmq_skt->send(zmq::message_t(header.data(), header.size()), zmq::send_flags::sndmore);
	zmq_skt->send(zmq::message_t(buffer.data(), buffer.size()), zmq::send_flags::none);
}

static int stockmq_bind(lua_State* L) {
	auto bind_address = luaL_checkstring(L, 1);
	auto udata = (StockMQ**)lua_newuserdata(L, sizeof(StockMQ*));
	*udata = new StockMQ();

	(*udata)->zmq_ctx = new zmq::context_t(1);
	(*udata)->zmq_skt = new zmq::socket_t(*(*udata)->zmq_ctx, ZMQ_REP);
	(*udata)->zmq_skt->bind(bind_address);

	luaL_getmetatable(L, METATABLE);
	lua_setmetatable(L, -2);
	return 1;
}

static int stockmq_process(lua_State* L) {
	auto s = stockmq_check(L, 1);

	if (s->zmq_skt) {
		s->zmq_err = 0;
		try {
			auto msg = zmq::message_t();

			if (s->zmq_skt->recv(msg, zmq::recv_flags::none)) {
				auto handle = msgpack::unpack(static_cast<const char*>(msg.data()), msg.size());
				auto status = STATUS_OK;

				auto buffer = msgpack::sbuffer();
				auto packer = msgpack::packer<msgpack::sbuffer>(buffer);

				if (handle.get().type == msgpack::type::ARRAY && 
					handle.get().via.array.size > 0 && 
					handle.get().via.array.ptr[0].type == msgpack::type::STR) {
					auto funcname = handle.get().via.array.ptr[0].as<std::string>();
					auto level = lua_gettop(L);
					lua_getglobal(L, funcname.c_str());
					if (!lua_isnil(L, -1)) {
						for (auto i = 1u; i < handle.get().via.array.size; i++) {
							stack_push(L, handle.get().via.array.ptr[i]);
						}

						auto top_prev = lua_gettop(L);
						if (!lua_pcall(L, handle.get().via.array.size - 1, LUA_MULTRET, 0)) {
							auto results = lua_gettop(L) - level;

							switch (results) {
							case 0:
								packer.pack_nil();
								break;
							case 1:
								stack_pack(packer, L, lua_gettop(L));
								break;
							default:
								packer.pack_array(results);
								for (auto i = results; i > 0; i--) {
									stack_pack(packer, L, lua_gettop(L) - i + 1);
								}
								break;
							}

							for (auto i = 0; i < results; i++) {
								lua_pop(L, 1);
							}
						}
						else {
							status = STATUS_ERROR;
							stack_pack(packer, L, -1);
							lua_pop(L, -1);
						}
					}
					else {
						status = STATUS_ERROR;
						packer.pack(std::format("{}:{}: function '{}' not found", __FILE__, __LINE__, funcname));
						lua_pop(L, -1);
					}
				}
				else {
					status = STATUS_ERROR;
					packer.pack(std::format("{}:{}: input should be array with first argument as string", __FILE__, __LINE__));
				}

				send_multipart(s->zmq_skt, status, buffer);
			}
		}
		catch (zmq::error_t ex) {
			s->zmq_err = ex.num();
		}
	}
	lua_pushinteger(L, static_cast<lua_Integer>(s->zmq_err));
	return 1;
}

static int stockmq_send(lua_State* L) {
	auto s = stockmq_check(L, 1);
	auto identity = luaL_checkstring(L, 2);
	luaL_checkany(L, 3);

	if (s->zmq_skt) {
		s->zmq_err = 0;
		try {
			auto buffer = msgpack::sbuffer();
			auto packer = msgpack::packer<msgpack::sbuffer>(buffer);

			stack_pack(packer, L, 3);
			send_multipart(s->zmq_skt, identity, buffer);
		}
		catch (zmq::error_t ex) {
			s->zmq_err = ex.num();
		}
	}

	lua_pushinteger(L, static_cast<lua_Integer>(s->zmq_err));
	return 1;
}

static int stockmq_errno(lua_State* L) {
	auto s = stockmq_check(L, 1);
	lua_pushinteger(L, static_cast<lua_Integer>(s->zmq_err));
	return 1;
}

static int stockmq_time(lua_State* L) {
	auto ts = std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
	lua_pushnumber(L, static_cast<lua_Number>(ts / 1000000.0));
	return 1;
}

static int stockmq_destructor(lua_State* L) {
	auto s = stockmq_check(L, 1);
	if (s->zmq_skt) {
		s->zmq_skt->close();
		delete s->zmq_skt;
	}
	if (s->zmq_ctx) {
		s->zmq_ctx->close();
		delete s->zmq_ctx;
	}
	delete s;
	return 0;
}

static luaL_Reg funcs[] = {
	{ "bind", stockmq_bind },
	{ "send", stockmq_send },
	{ "process", stockmq_process },
	{ "errno", stockmq_errno },
	{ "time", stockmq_time },
	{ "__gc", stockmq_destructor },
	{ NULL, NULL }
};

extern "C" LUALIB_API int luaopen_stockmq(lua_State * L) {
	luaL_checkversion(L);
	luaL_newmetatable(L, METATABLE);
	luaL_setfuncs(L, funcs, 0);
	lua_pushvalue(L, -1);
	lua_setfield(L, -1, "__index");
	lua_setglobal(L, STOCKMQ);
	return 1;
}
