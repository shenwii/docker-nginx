#!/bin/sh

INIT_FILE="/.lua_init"
if [ ! -f "$INIT_FILE" -a -n "$LUAROCKS_PACKAGES" ]; then
    echo "Initializing LuaRocks packages..."
    apk add --no-cache --virtual .luarocks luarocks
    luarocks install $(echo "$LUAROCKS_PACKAGES" | tr ',' ' ') || { echo "Failed to install LuaRocks packages: $LUAROCKS_PACKAGES"; apk del .luarocks; exit 1; }
    apk del .luarocks
    echo "LuaRocks packages installed."
    touch "$INIT_FILE"
fi
