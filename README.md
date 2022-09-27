# ①ディレクトリを作成

```
mkdir rails_api_app
cd rails_api_app
```

## ②各種設定ファイルを準備する

```
% touch {docker-compose.yml,Dockerfile,Gemfile,Gemfile.lock,entrypoint.sh}
```

**Dockerfile**
```sh:Dockerfile
# FROM：使用するイメージ、バージョン
FROM ruby:3.1
# 公式→https://hub.docker.com/_/ruby

# Rails 7ではWebpackerが標準では組み込まれなくなったので、yarnやnodejsのインストールが不要

# ruby3.1のイメージがBundler version 2.3.7で失敗するので、gemのバージョンを追記
ARG RUBYGEMS_VERSION=3.3.20

# RUN：任意のコマンド実行
RUN mkdir /app

# WORKDIR：作業ディレクトリを指定
WORKDIR /app

# COPY：コピー元とコピー先を指定
# ローカルのGemfileをコンテナ内の/app/Gemfileに
COPY Gemfile /app/Gemfile

COPY Gemfile.lock /app/Gemfile.lock

# RubyGemsをアップデート
RUN gem update --system ${RUBYGEMS_VERSION} && \
    bundle install

COPY . /app

# コンテナ起動時に実行させるスクリプトを追加
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3001

# CMD:コンテナ実行時、デフォルトで実行したいコマンド
# Rails サーバ起動
CMD ["rails", "server", "-b", "0.0.0.0"]
```

Bundlerのバージョンが2.3.7だと`NameError: uninitialized constant Gem::Source`が発生するので、`RUBYGEMS_VERSION=3.3.20`にした
https://qiita.com/P-man_Brown/items/32fdba14e88219f8d2f0


**docker-compose.yml**
```sh:docker-compose.yml
version: '3'
services:
  web:
    build: .
    # 毎回 rm tmp/pids/server.pid するのも手間であるため、・事前に手元で/tmp/pids/server.pidを削除する
    command: /bin/sh -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 3001 -b '0.0.0.0'"
    volumes:
      - .:/app
    ports:
      - 3001:3001
    depends_on:
      - db
    # railsでpryする用
    # true を指定することでコンテナを起動させ続けることができます。   
    tty: true
    # stdin_openとは標準入出力とエラー出力をコンテナに結びつける設定です。
    stdin_open: true
  db:
    image: mysql:5.7
    # M1のCPUは、linux/arm64/v8なのですが、使用しようとしたimageがこれに対応していないというエラーが起きる
    # m1はplatformを指定して、linux/amd64にエミュレートする指定をすることで正常に動くようになります
    platform: linux/amd64
    # DBのレコードが日本語だと文字化けするので、utf8をセットする
    command: mysqld --character-set-server=utf8 --collation-server=utf8_unicode_ci
    volumes:
      - db-volume:/var/lib/mysql
    # 環境変数
    environment:
      MYSQL_ROOT_PASSWORD: password
      TZ: "Asia/Tokyo"
    ports:
      - "3306:3306"
# PC上にdb-volumeという名前でボリューム（データ領域）が作成される
# コンテナを作り直したとしてもPC上に残るようにするために設定
volumes:
  db-volume:
```


GemfileでRails 7系を指定する

**Gemfile**
```:Gemfile
source 'https://rubygems.org'
gem 'rails', '~>7.0.3'
```

特定のファイルが既に存在する場合にサーバーの再起動を妨げる Rails 固有の問題を修正するエントリポイントスクリプトを提供します。このスクリプトは、コンテナが開始されるたびに実行されます。

**entrypoint.sh**
```sh:entrypoint.sh
# set -e は「エラーが発生するとスクリプトを終了する」オプション
#!/bin/bash
set -e

# rm ではrailsのpidを削除
# Rails に対応したファイル server.pid が存在しているかもしれないので削除する。
rm -f /app/tmp/pids/server.pid

# exec "$@"でCMDで渡されたコマンドを実行しています。(→rails s)
# コンテナのプロセスを実行する。（Dockerfile 内の CMD に設定されているもの。）
exec "$@"
```

詳細は以下をご確認ください
[クィックスタート: Compose と Rails
](https://matsuand.github.io/docs.docker.jp.onthefly/samples/rails/
)


# ③Rails プロジェクト立ち上げ

apiモードでrails new

```
% docker-compose run --rm web rails new . --force --database=mysql --api
```

# ④イメージの構築
```
% docker-compose build
```

# ⑤MySQLの設定

Dockerfileで設定したpasswordとhost名を修正する

**config/database.yml**

```yml:config/database.yml
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: password
  host: db
```

# ⑥DBの作成

```
% docker-compose run --rm web rails db:create
Creating rails_backend_web_run ... done
Created database 'app_development'
Created database 'app_test'
```


# ⑦コンテナの作成と起動

```
% docker-compose up -d
```


# ⑧ローカルホストに接続

http://localhost:3001/ にアクセスする

以下が表示されれば完了
![](https://storage.googleapis.com/zenn-user-upload/b0c1c7436e79-20220820.png)


# ローカルで動かす

git clone後

```
docker-compose build
docker-compose run --rm web rails db:create
docker-compose up　-d
```

http://localhost:3001/ にアクセス


# 環境

```
Apple M1 Pro
macOS BigSur 12.1
Docker Engine 20.10.12
Docker Compose 1.29.2
Ruby 3.1
Ruby on Rails 7.0.1
MySQL　5.7
```
