#ifndef _TTY_H_
#define _TTY_H_

#include <windows.h>
#include <stdio.h>
#include <conio.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

//static int l_enableRawMode();
//static int l_disableRawMode();
static int l_read_chr(lua_State* L);

#endif 