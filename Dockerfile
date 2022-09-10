# FROM：使用するイメージ、バージョン
FROM ruby:3.1
# rubyのバージョン3.1のイメージをとってきて使うぜ！
# 公式→https://hub.docker.com/_/ruby

# Rails 7ではWebpackerが標準では組み込まれなくなったので、yarnやnodejsのインストールが不要

# ruby3.1のイメージがBundler version 2.3.7で失敗するので、gemのバージョンを追記
ARG RUBYGEMS_VERSION=3.3.20

# RUN：任意のコマンド実行をするぜ！
RUN mkdir /app

# WORKDIR：作業ディレクトリを指定するぜ！
WORKDIR /app

# COPY：コピー元とコピー先を指定するぜ！
COPY Gemfile /app/Gemfile
# ローカルのGemfileをコンテナ内の/app/Gemfileに

COPY Gemfile.lock /app/Gemfile.lock
# RubyGemsをアップデート
RUN gem update --system ${RUBYGEMS_VERSION} && \
    bundle install
# COPY した Gemfile.lock に BUNDLED WITH 2.3.7 または 2.3.8 と記述されている場合は 
# bundle install の前に bundle update --bundler を実行して Gemfile.lock　を更新する必要あり。
# RUN bundle install

COPY . /app

# Add a script to be executed every time the container starts.
# コンテナ起動時に実行させるスクリプトを追加
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3001

# Start the main process.
# Rails サーバ起動
CMD ["rails", "server", "-b", "0.0.0.0"]