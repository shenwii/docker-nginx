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
            if [ -n "$module" ]; then
                sed -i "1i load_module $module;" /etc/nginx/nginx.conf
            fi
        done
    )
fi

if [ "$USE_STREAM" = "1" ]; then
    cat >> /etc/nginx/nginx.conf << EOF
stream {
    include /etc/nginx/stream-conf.d/*.conf;
}
EOF
fi
