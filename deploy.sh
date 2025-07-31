#!/bin/bash
set -e

# Pleasanter自動デプロイスクリプト
echo "Pleasanter自動デプロイを開始します..."

# 必要なパッケージのインストール
echo "必要なパッケージをインストールしています..."
apt-get update
apt-get install -y git docker.io docker-compose curl jq

# Dockerサービスの開始
echo "Dockerサービスを開始しています..."
systemctl start docker
systemctl enable docker

# .envファイルの存在確認
if [ ! -f .env ]; then
  echo "環境設定ファイル(.env)が見つかりません。サンプルからコピーします。"
  cp .env.sample .env
  echo "環境設定ファイル(.env)を編集してください。"
  exit 1
fi

# 環境変数の読み込み
echo "環境変数を読み込んでいます..."
source .env

# データベース初期化スクリプトの作成
echo "データベース初期化スクリプトを準備しています..."
mkdir -p ./init-scripts
cat > ./init-scripts/init-db.sh << EOL
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "\$POSTGRES_USER" --dbname "\$POSTGRES_DB" << EOSQL
CREATE DATABASE pleasanter;
EOSQL
EOL
chmod +x ./init-scripts/init-db.sh

# Dockerコンテナのビルドと起動
echo "Dockerコンテナをビルドして起動しています..."
docker-compose up -d

echo "Pleasanterのデプロイが完了しました！"
echo "ブラウザで http://サーバーのIPアドレス:8080 にアクセスしてください。"
echo "初期ユーザー: Administrator"
echo "初期パスワード: pleasanter"