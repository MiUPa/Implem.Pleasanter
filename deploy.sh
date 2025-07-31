#!/bin/bash
set -e

# Pleasanter自動デプロイスクリプト
echo "Pleasanter自動デプロイを開始します..."

# 必要なパッケージのインストール
echo "必要なパッケージをインストールしています..."
apt-get update
apt-get install -y git docker.io docker-compose curl jq openssl

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

# Nginxディレクトリの作成
echo "Nginx設定ディレクトリを作成しています..."
mkdir -p ./nginx/conf.d
mkdir -p ./nginx/ssl
mkdir -p ./nginx/logs

# サーバー名の取得
SERVER_NAME=${SERVER_NAME:-localhost}
echo "サーバー名: $SERVER_NAME"

# SSL証明書の生成
echo "SSL証明書を生成しています..."
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout ./nginx/ssl/pleasanter.key \
  -out ./nginx/ssl/pleasanter.crt \
  -subj "/CN=$SERVER_NAME" \
  -addext "subjectAltName=DNS:$SERVER_NAME,IP:127.0.0.1" \
  -batch

# HTTPSの設定ファイルを作成
cat > ./nginx/conf.d/default.conf << EOL
server {
    listen 80;
    server_name _;
    
    # HTTPをHTTPSにリダイレクト
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/pleasanter.crt;
    ssl_certificate_key /etc/nginx/ssl/pleasanter.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    
    location / {
        proxy_pass http://Implem.Pleasanter:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocketのサポート
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # タイムアウト設定
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
        
        # 大きなファイルのアップロードを許可
        client_max_body_size 100M;
    }
}
EOL

# Dockerコンテナのビルドと起動
echo "Dockerコンテナをビルドして起動しています..."
docker-compose up -d

echo "Pleasanterのデプロイが完了しました！"
echo "ブラウザで https://$SERVER_NAME にアクセスしてください。"
echo "初期ユーザー: Administrator"
echo "初期パスワード: pleasanter"