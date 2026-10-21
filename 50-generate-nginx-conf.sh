#!/bin/sh

if [ -f /etc/nginx/nginx.conf ]; then
    echo "nginx.conf already exists, skipping generation."
    exit 0
fi

envsubst '$NGINX_USER' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

if [ -n "$LOAD_MODULES" ]; then
    (
        IFS=","
        for module in $LOAD_MODULES; do
            if [ -z "$module" ]; then continue; fi
            sed -i "1i load_module $module;" /etc/nginx/nginx.conf
        done
    )
fi

if [ "$USE_STREAM" = "1" ]; then
    cat >> /etc/nginx/nginx.conf << EOF
stream {
    log_format proxy '$remote_addr [$time_local] '
                     '$protocol $status $bytes_sent $bytes_received '
                     '$session_time "$upstream_addr"';

    access_log  /var/log/nginx/access.log  proxy;

    lua_package_path "/etc/nginx/lualib/?.lua;/usr/share/lua/5.1/?.lua;/usr/share/lua/5.1/?/init.lua";

    include /etc/nginx/stream-conf.d/*.conf;
}
EOF
fi
