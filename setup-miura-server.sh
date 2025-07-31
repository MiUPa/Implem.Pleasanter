#!/bin/bash

# XServer VPS用のPleasanter環境セットアップスクリプト

set -e

echo "===== Pleasanter環境セットアップを開始します ====="

# 必要なパッケージのインストール
echo "必要なパッケージをインストール中..."
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Dockerのインストール
echo "Dockerをインストール中..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
fi

# Docker Composeのインストール
echo "Docker Composeをインストール中..."
if ! command -v docker-compose &> /dev/null; then
    apt-get install -y docker-compose-plugin
fi

# ファイアウォールの設定
echo "ファイアウォールを設定中..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
fi

# 作業ディレクトリの作成
echo "作業ディレクトリを作成中..."
mkdir -p /opt/pleasanter
mkdir -p /opt/pleasanter/nginx/ssl
mkdir -p /opt/pleasanter/nginx/letsencrypt
mkdir -p /opt/pleasanter/logs

# 環境変数ファイルの確認
if [ ! -f "/opt/pleasanter/.env" ]; then
    echo "環境変数ファイルを作成中..."
    cp .env /opt/pleasanter/
    echo "環境変数ファイルを作成しました"
fi

# Docker Composeファイルのコピー
echo "Docker Compose設定ファイルをコピー中..."
cp docker-compose.ssl.yml /opt/pleasanter/
cp -r nginx /opt/pleasanter/
cp -r init-db /opt/pleasanter/
cp deploy-ssl.sh /opt/pleasanter/

# 実行権限の付与
chmod +x /opt/pleasanter/deploy-ssl.sh

echo "===== セットアップが完了しました ====="
echo "次のコマンドを実行してデプロイしてください："
echo "cd /opt/pleasanter && ./deploy-ssl.sh"