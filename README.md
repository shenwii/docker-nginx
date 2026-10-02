# nginx-docker

A custom nginx container image built from source, with a newer OpenSSL 4.0 stack and selected modules for modern TLS and application-layer filtering.

[中文](README.zh-CN.md) | [日本語](README.ja-JP.md)

## Highlights

- Built from source with OpenSSL 4.0.2
- Enables ECH support via OpenSSL 4.0+
- Includes LuaJIT support via the `lua-nginx-module`
- Includes ModSecurity v3 integration via the `ModSecurity-nginx` connector
- Keeps the runtime image lightweight by removing build-time headers and unused artifacts
- Designed to be close to the official nginx container layout, while leaving actual service configuration entirely to the user

## Important behavior

This image intentionally does not define any default `server` block.

That means:

- it does not listen on port 80 unless the user adds a config
- the main nginx config still keeps `include /etc/nginx/conf.d/*.conf;`
- users are expected to place their own nginx config files in `/etc/nginx/conf.d` to define services

This is by design. The image is meant to be a reusable nginx binary + module environment, not a preconfigured web server with a dummy default site. The standard `conf.d` hook remains available so the end user can drop in their own site configuration files.

## Why this image

This image is intended for cases where you want a more modern nginx build than the stock distro package, while still keeping the container layout familiar.

The main customization points are:

1. OpenSSL 4.0 build
   - Allows newer TLS features, including ECH support.
   - The OpenSSL build uses `make install_sw` to keep only the runtime essentials.

2. LuaJIT integration
   - `lua-nginx-module` is included.
   - `lua-resty-core` and `lua-resty-lrucache` are installed into `/etc/nginx/lualib`.

3. ModSecurity integration
   - ModSecurity is built and linked into nginx as a module.
   - Useful for WAF or request inspection workflows.

4. Official nginx container style
   - The image follows the standard nginx runtime layout, including `/etc/nginx`, `/var/log/nginx`, `/var/cache/nginx`, and `/docker-entrypoint.d`.
   - Template-based configuration is supported through the built-in entrypoint scripts.

## Included components

- nginx 1.31.6
- OpenSSL 4.0.2
- ModSecurity v3.0.17
- LuaJIT
- `ngx_devel_kit`
- `lua-nginx-module`
- `lua-resty-core`
- `lua-resty-lrucache`

## Image layout

Key runtime paths:

- `/etc/nginx` : nginx configuration
- `/etc/nginx/conf.d` : user-provided site config files
- `/etc/nginx/templates` : template files for env-substitution workflows
- `/etc/nginx/lualib` : Lua libraries
- `/var/log/nginx` : access and error logs
- `/var/cache/nginx` : temp/cache directories
- `/docker-entrypoint.d` : startup scripts and env templates

## Entrypoint and template support

The image includes:

- `docker-entrypoint.sh`
- `15-local-resolvers.envsh`
- `20-envsubst-on-templates.sh`

These follow the common nginx Docker pattern:

- run scripts from `/docker-entrypoint.d` before startup
- source `.envsh` variables when needed
- substitute environment variables in templates for config files

This is intended to be compatible with the common "official nginx container" style, but the actual service configuration is left to the end user.

## Build

```bash
podman build -t nginx-docker .
```

## Quick validation

Check that the compiled nginx binary works and prints its build configuration:

```bash
podman run --rm nginx-docker nginx -V
```

Check nginx configuration syntax without requiring any default service:

```bash
podman run --rm nginx-docker nginx -t
```

## Example custom config

If you want to add a site, mount a config under `/etc/nginx/conf.d/` and then run nginx:

```bash
podman run --rm -it \
  -v $(pwd)/site.conf:/etc/nginx/conf.d/site.conf:ro \
  nginx-docker \
  nginx -g 'daemon off;'
```

Example `site.conf`:

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        return 200 'hello from nginx\n';
    }
}
```

## Notes

- The image is designed for flexibility and experimentation rather than as a pre-wired demo site.
- The Dockerfile keeps the build toolchain in the builder stage and copies only the runtime artifacts into the final stage.
- `make install_sw` is used for OpenSSL because it is the correct minimal runtime install for the OpenSSL binary and library set.
- The final image removes build-only headers and unused artifacts to reduce size.

## License

See `LICENSE` for project licensing details.
