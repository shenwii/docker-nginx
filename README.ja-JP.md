# nginx-docker

ソースコードからビルドしたカスタム nginx コンテナイメージです。より新しい OpenSSL 4.0 スタックを使用し、モダンな TLS とアプリケーション層のフィルタリングに必要なモジュールを組み込みました。

[English](README.md) | [中文](README.zh-CN.md)

## 特徴

- ソースコードからビルドした OpenSSL 4.0.2
- OpenSSL 4.0+ による ECH サポート
- LuaJIT と `lua-nginx-module` を統合
- ModSecurity v3 と `ModSecurity-nginx` を統合
- 実行時イメージを軽量化し、ビルド時のヘッダや不要な成果物を除去
- 公式 nginx コンテナの構成に近いが、実際のサービス設定は利用者が完全に決める設計

## 重要な動作

このイメージは、デフォルトの `server` ブロックを一切定義しません。

つまり次の通りです：

- デフォルトでは 80 番ポートを待ち受けしない
- `/etc/nginx/conf.d/*.conf` を自動的に include しない
- サービスを提供したい場合は、利用者が nginx の設定ファイルを自分で準備する

これは意図的な設計です。このイメージは「使い捨てのデモサイト付き Web サーバー」ではなく、「再利用可能な nginx バイナリ + モジュール環境」を目的としています。

## このイメージの理由

このイメージは、標準のディストリビューションパッケージより新しい nginx を使いたいが、コンテナの使い方はできるだけ公式イメージに近く保ちたいケース向けです。

主なカスタマイズ点は次のとおりです：

1. OpenSSL 4.0
   - 新しい TLS 機能、ECH を含む機能を利用できるようにする。
   - `make install_sw` を使い、実行時に必要なバイナリとライブラリだけを残す。

2. LuaJIT 統合
   - `lua-nginx-module` を含む。
   - `lua-resty-core` と `lua-resty-lrucache` は `/etc/nginx/lualib` にインストールされる。

3. ModSecurity 統合
   - ModSecurity を nginx に組み込み、WAF やリクエスト検査用途に利用できる。

4. 公式 nginx コンテナ風レイアウト
   - `/etc/nginx`、`/var/log/nginx`、`/var/cache/nginx`、`/docker-entrypoint.d` などの典型的なディレクトリ構成を採用。
   - entrypoint とテンプレート変数置換により、公式イメージに近い運用が可能。

## 含まれるコンポーネント

- nginx 1.31.6
- OpenSSL 4.0.2
- ModSecurity v3.0.17
- LuaJIT
- `ngx_devel_kit`
- `lua-nginx-module`
- `lua-resty-core`
- `lua-resty-lrucache`

## イメージの構造

主な実行時パス：

- `/etc/nginx`：nginx の設定ディレクトリ
- `/etc/nginx/conf.d`：ユーザーが置くサイト設定
- `/etc/nginx/templates`：テンプレートファイル、環境変数置換用
- `/etc/nginx/lualib`：Lua ライブラリ
- `/var/log/nginx`：アクセスログとエラーログ
- `/var/cache/nginx`：キャッシュと一時ディレクトリ
- `/docker-entrypoint.d`：起動スクリプトと環境変数テンプレート

## Entrypoint とテンプレート対応

イメージには次のものが含まれています：

- `docker-entrypoint.sh`
- `15-local-resolvers.envsh`
- `20-envsubst-on-templates.sh`

これらは一般的な nginx Docker の流儀に従っており：

- 起動前に `/docker-entrypoint.d` 中のスクリプトを実行
- 必要に応じて `.envsh` を読み込み
- テンプレートファイルに環境変数を展開

という動作を行います。

ただし、実際のサービス設定は利用者が行う前提です。

## ビルド

```bash
podman build -t nginx-docker .
```

## クイック検証

コンパイルされた nginx バイナリが正常に動作し、ビルド設定を出力できるか確認：

```bash
podman run --rm nginx-docker nginx -V
```

デフォルトのサービスがなくても nginx の設定構文チェックができるか確認：

```bash
podman run --rm nginx-docker nginx -t
```

## 例: カスタム設定

独自のサイト定義を追加したい場合は、`/etc/nginx/conf.d/` に設定ファイルをマウントします：

```bash
podman run --rm -it \
  -v $(pwd)/site.conf:/etc/nginx/conf.d/site.conf:ro \
  nginx-docker \
  nginx -g 'daemon off;'
```

例: `site.conf`

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        return 200 'hello from nginx\n';
    }
}
```

## 備考

- このイメージは「事前に用意されたデモサイト」ではなく、汎用的な nginx コンパイル環境を意図しています。
- Dockerfile はビルド用ツールチェーンを builder ステージに置き、実行時に必要なものだけを最終段へコピーします。
- OpenSSL は `make install_sw` を使っており、これは最小限の実行時インストールとして妥当です。
- 最終イメージでは、ビルド時のヘッダや不要な成果物を削除してサイズを抑えています。

## ライセンス

詳細は `LICENSE` を参照してください。
