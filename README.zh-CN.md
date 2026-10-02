# nginx-docker

一个基于源码编译的自定义 nginx 容器镜像，使用较新的 OpenSSL 4.0 栈，并集成了现代 TLS 和应用层过滤所需的模块。

[English](README.md) | [日本語](README.ja-JP.md)

## 特点

- 基于源码编译 OpenSSL 4.0.2
- 通过 OpenSSL 4.0+ 开启 ECH 支持
- 集成 LuaJIT 和 `lua-nginx-module`
- 集成 ModSecurity v3 和 `ModSecurity-nginx`
- 运行时镜像尽量精简，删除了编译阶段的头文件和无用产物
- 结构尽量贴近官方 nginx 容器布局，但不强制内置任何默认站点

## 重要行为

这个镜像故意不定义任何默认 `server` 块。

也就是说：

- 默认不监听 80 端口
- 不会自动 include `/etc/nginx/conf.d/*.conf`
- 如果用户希望提供服务，必须自己准备 nginx 配置文件

这是有意为之的设计。这个镜像的目标是提供一个“可复用的 nginx 二进制 + 模块环境”，而不是一个自带默认站点的 Web 容器。

## 为什么选择这个镜像

这个镜像适合需要比系统包更现代 nginx 构建版本的场景，同时仍然保留 Docker 官方容器的使用习惯。

主要定制点包括：

1. OpenSSL 4.0
   - 支持较新的 TLS 特性，包括 ECH。
   - 使用 `make install_sw` 来保留运行时所需的二进制和库文件。

2. LuaJIT 集成
   - 包含 `lua-nginx-module`。
   - `lua-resty-core` 和 `lua-resty-lrucache` 会安装到 `/etc/nginx/lualib`。

3. ModSecurity 集成
   - ModSecurity 会被编译并接入 nginx。
   - 适合 WAF 或请求过滤场景。

4. 类官方 nginx 容器布局
   - 运行时目录包括 `/etc/nginx`、`/var/log/nginx`、`/var/cache/nginx` 和 `/docker-entrypoint.d`。
   - 入口脚本和模板变量替换机制与官方容器风格相近。

## 包含的组件

- nginx 1.31.6
- OpenSSL 4.0.2
- ModSecurity v3.0.17
- LuaJIT
- `ngx_devel_kit`
- `lua-nginx-module`
- `lua-resty-core`
- `lua-resty-lrucache`

## 镜像目录结构

关键运行时路径：

- `/etc/nginx`：nginx 配置目录
- `/etc/nginx/conf.d`：用户自定义站点配置
- `/etc/nginx/templates`：模板文件，用于环境变量替换流程
- `/etc/nginx/lualib`：Lua 运行库
- `/var/log/nginx`：访问日志和错误日志
- `/var/cache/nginx`：缓存和临时目录
- `/docker-entrypoint.d`：启动脚本和环境变量模板

## Entrypoint 与模板支持

镜像内包含：

- `docker-entrypoint.sh`
- `15-local-resolvers.envsh`
- `20-envsubst-on-templates.sh`

这些脚本遵循常见的 nginx Docker 方式：

- 在启动前执行 `/docker-entrypoint.d` 下的脚本
- 根据需要加载 `.envsh` 环境变量
- 对模板文件执行环境变量替换

这种设计意在兼容官方 nginx 容器的用法，但最终真正的服务配置由使用者自行提供。

## 构建

```bash
podman build -t nginx-docker .
```

## 快速验证

检查编译出来的 nginx 二进制是否正常，并打印编译配置：

```bash
podman run --rm nginx-docker nginx -V
```

检查 nginx 配置语法，但不要求存在默认站点：

```bash
podman run --rm nginx-docker nginx -t
```

## 示例：自定义配置

如果你要提供自己的站点配置，可以挂载到 `/etc/nginx/conf.d/`：

```bash
podman run --rm -it \
  -v $(pwd)/site.conf:/etc/nginx/conf.d/site.conf:ro \
  nginx-docker \
  nginx -g 'daemon off;'
```

示例 `site.conf`：

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        return 200 'hello from nginx\n';
    }
}
```

## 备注

- 这个镜像更偏“通用 nginx 编译环境”，而非预装好的 demo 站点。
- Dockerfile 将编译工具链放在 builder 阶段，最终阶段只保留运行时所需文件。
- OpenSSL 使用 `make install_sw`，这是最合理的最小运行时安装方式。
- 最终镜像会移除编译头文件及其他非运行时内容，以减小体积。

## 许可证

详情见 `LICENSE`。
