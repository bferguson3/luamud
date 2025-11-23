#include "tty.h"

//__declspec(dllexport)
// gcc -shared -o tty.dll -lluajit tty.c -Ic:\Users\ben\Projects\luajit-dist\include -Lc:\Users\ben\Projects\luajit-dist

/*
Looks like these don't work...
// Function to enable raw mode
static int l_enableRawMode(lua_State* L) {
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    DWORD mode;
    GetConsoleMode(hStdin, &mode);
    //mode |= ENABLE_PROCESSED_OUTPUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    //SetConsoleMode(hStdin, mode &~(ENABLE_ECHO_INPUT|ENABLE_LINE_INPUT));
    //printf("Hello World\n");
	return 0;
}

// Function to disable raw mode and restore original settings
static int l_disableRawMode(lua_State* L) {
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    DWORD mode;
    GetConsoleMode(hStdin, &mode);
    //mode &= ~(ENABLE_PROCESSED_OUTPUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    SetConsoleMode(hStdin, mode | ENABLE_LINE_INPUT);
	return 0;
}
*/

static int l_read_chr(lua_State* L) { 
	if (kbhit()){
        lua_pushnumber(L, getch());
	} else { 
        lua_pushnumber(L, 0);
    }
    return 1;
}

static const struct luaL_Reg mylib[] = { 
	//{"enable_raw_mode", l_enableRawMode}, 
	//{"disable_raw_mode", l_disableRawMode},
	{"read_chr", l_read_chr},
	{NULL, NULL}
};

int luaopen_tty(lua_State* L){
	luaL_register(L, "tty", mylib);
	return 1;
}

int main() {
    return 0;
}