# syntax=docker/dockerfile:1

FROM cgr.dev/chainguard/wolfi-base AS builder

ENV NGINX_VERSION=1.31.6
ENV OPENSSL_VERSION=4.0.2
ENV MODSECURITY_VERSION=v3.0.17

RUN addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apk add --no-cache --virtual .build-deps \
        build-base \
        curl \
        git \
        libaio-dev \
        linux-headers \
        luajit-dev \
        pcre2-dev \
        perl \
        zlib-dev \
    && export LUAJIT_LIB=$(pkg-config --variable=libdir luajit) \
    && export LUAJIT_INC=$(pkg-config --variable=includedir luajit) \
    && cd /root/ \
    && curl -f -L -O https://github.com/owasp-modsecurity/ModSecurity/releases/download/${MODSECURITY_VERSION}/modsecurity-${MODSECURITY_VERSION}.tar.gz \
    && tar -xvzf modsecurity-${MODSECURITY_VERSION}.tar.gz \
    && cd modsecurity-${MODSECURITY_VERSION} \
    && ./configure --prefix=/usr/local --enable-shared \
    && make -j$(nproc) \
    && make install-strip \
    && cd /root/ \
    && curl -f -L -O https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar -xvzf openssl-${OPENSSL_VERSION}.tar.gz \
    && cd openssl-${OPENSSL_VERSION} \
    && ./Configure --prefix=/usr/local --libdir=lib shared zlib \
    && make -j$(nproc) \
    && make install_sw \
    && cd /root/ \
    && git clone --depth 1 'https://github.com/openresty/lua-nginx-module' \
    && git clone --depth 1 'https://github.com/vision5/ngx_devel_kit' \
    && git clone --depth 1 'https://github.com/owasp-modsecurity/ModSecurity-nginx' \
    && curl -f -L -O https://github.com/nginx/nginx/releases/download/release-${NGINX_VERSION}/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xvzf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/run/nginx.pid --lock-path=/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_v3_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-O2 -Werror=implicit-function-declaration -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" --add-module=../ngx_devel_kit --add-module=../lua-nginx-module --add-module=../ModSecurity-nginx \
    && make -j$(nproc) \
    && make install \
    && cd /root/ \
    && git clone --depth 1 'https://github.com/openresty/lua-resty-core' \
    && cd lua-resty-core \
    && make install LUA_LIB_DIR=/etc/nginx/lualib \
    && cd /root/ \
    && git clone --depth 1 'https://github.com/openresty/lua-resty-lrucache' \
    && cd lua-resty-lrucache \
    && make install LUA_LIB_DIR=/etc/nginx/lualib \
    && cd /root/ \
    && find /usr/local/lib -type f \( -name '*.a' -o -name '*.la' \) -delete

FROM cgr.dev/chainguard/wolfi-base

RUN addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apk add --no-cache libaio zlib pcre2 gettext-envsubst luajit libstdc++ \
    && mkdir /docker-entrypoint.d \
    && mkdir -p /etc/nginx/conf.d \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/cache/nginx/ \
    && mkdir -p /etc/nginx/templates \
    && touch /run/nginx.pid \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -f /etc/nginx/nginx.conf

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/local/lib /usr/lib
COPY --from=builder /usr/local/bin/openssl /usr/bin/openssl

COPY nginx.conf /etc/nginx/nginx.conf
COPY docker-entrypoint.sh /
COPY 15-local-resolvers.envsh /docker-entrypoint.d
COPY 20-envsubst-on-templates.sh /docker-entrypoint.d
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
