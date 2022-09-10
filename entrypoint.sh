#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"

# 次に、特定のファイルが既に存在する場合にサーバーの再起動を妨げる Rails 固有の問題を修正するエントリポイント スクリプトを提供します。このスクリプトは、コンテナーが開始されるたびに実行されます。 entrypoint.shで構成されています
# set -e は　「エラーが発生するとスクリプトを終了する」オプション
# rm ではrailsのpidを削除
# exec "$@"でCMDで渡されたコマンドを実行しています。(rails s)

