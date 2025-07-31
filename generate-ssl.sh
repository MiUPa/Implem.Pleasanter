#!/bin/bash
set -e

# SSL証明書生成スクリプト
echo "SSL証明書を生成しています..."

# 必要なディレクトリの作成
mkdir -p ./nginx/ssl
mkdir -p ./nginx/logs

# OpenSSLがインストールされているか確認
if ! command -v openssl &> /dev/null; then
    echo "OpenSSLがインストールされていません。インストールしています..."
    apt-get update && apt-get install -y openssl
fi

# サーバー名の取得
read -p "サーバーのドメイン名またはIPアドレスを入力してください（例：example.com または 192.168.1.100）: " SERVER_NAME

# SSL証明書の生成
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout ./nginx/ssl/pleasanter.key \
  -out ./nginx/ssl/pleasanter.crt \
  -subj "/CN=$SERVER_NAME" \
  -addext "subjectAltName=DNS:$SERVER_NAME,IP:127.0.0.1"

echo "SSL証明書が生成されました。"

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

echo "Nginxの設定ファイルが更新されました。"