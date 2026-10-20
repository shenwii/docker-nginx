#!/bin/sh

INIT_FILE="/.lua_init"
if [ ! -f "$INIT_FILE" -a -n "$LUAROCKS_PACKAGES" ]; then
    echo "Initializing LuaRocks packages..."
    apk add --no-cache --virtual .luarocks luarocks
    (
        IFS=","
        for package in $LUAROCKS_PACKAGES; do
            if [ -z "$package" ]; then continue; fi
            echo "Installing LuaRocks package: $package"
            luarocks install "$package" || { echo "Failed to install LuaRocks package: $package"; }
        done
    )
    apk del .luarocks
    echo "LuaRocks packages installed."
    touch "$INIT_FILE"
fi
