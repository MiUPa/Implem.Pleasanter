#!/bin/bash

# Pleasanter SSL対応自動デプロイメントスクリプト
# 使用方法: ./deploy-ssl.sh

set -e

# 色付きログ出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 環境変数ファイルの確認
if [ ! -f ".env" ]; then
    log_error ".env ファイルが見つかりません。env.ssl.example をコピーして設定してください。"
    exit 1
fi

# 環境変数の読み込み
source .env

# 必須環境変数の確認
if [ "$DOMAIN_NAME" = "your-domain.com" ] || [ "$SERVER_IP" = "your-server-ip" ] || [ "$SSL_EMAIL" = "your-email@example.com" ]; then
    log_error "環境変数が正しく設定されていません。.env ファイルを確認してください。"
    log_error "必須設定項目:"
    log_error "  - DOMAIN_NAME: ドメイン名"
    log_error "  - SERVER_IP: サーバーIPアドレス"
    log_error "  - SSL_EMAIL: SSL証明書用メールアドレス"
    exit 1
fi

log_info "Pleasanter SSL対応デプロイメントを開始します"
log_info "サーバーIP: $SERVER_IP"
log_info "ドメイン: $DOMAIN_NAME"
log_info "SSLメール: $SSL_EMAIL"

# 前提条件の確認
log_step "前提条件の確認中..."

# Docker の確認とインストール
if ! command -v docker &> /dev/null; then
    log_warn "Docker がインストールされていません。インストールを開始します..."
    
    # OS判定
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        log_info "Ubuntu/Debian 用のDockerをインストール中..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        log_info "Docker のインストールが完了しました"
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        log_info "CentOS/RHEL 用のDockerをインストール中..."
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        log_info "Docker のインストールが完了しました"
    else
        log_error "サポートされていないOSです。手動でDockerをインストールしてください。"
        exit 1
    fi
else
    log_info "Docker は既にインストールされています"
fi

# Docker Compose の確認とインストール
if ! command -v docker-compose &> /dev/null; then
    log_warn "Docker Compose がインストールされていません。インストールを開始します..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        log_info "Ubuntu/Debian 用のDocker Composeをインストール中..."
        sudo apt-get update
        sudo apt-get install -y docker-compose-plugin
        # 従来のdocker-composeもインストール
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        log_info "CentOS/RHEL 用のDocker Composeをインストール中..."
        sudo yum install -y docker-compose-plugin
        # 従来のdocker-composeもインストール
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        log_error "サポートされていないOSです。手動でDocker Composeをインストールしてください。"
        exit 1
    fi
    
    log_info "Docker Compose のインストールが完了しました"
else
    log_info "Docker Compose は既にインストールされています"
fi

# 必要なディレクトリの作成
log_step "必要なディレクトリを作成中..."
mkdir -p nginx/ssl
mkdir -p nginx/letsencrypt
mkdir -p logs

# バックアップの作成
log_step "既存データのバックアップを作成中..."
if [ -d "data" ]; then
    tar -czf "backup-ssl-$(date +%Y%m%d-%H%M%S).tar.gz" data/
    log_info "バックアップが作成されました"
fi

# 既存のコンテナを停止
log_step "既存のコンテナを停止中..."
docker-compose -f docker-compose.ssl.yml down || true

# イメージを再ビルド
log_step "Docker イメージをビルド中..."
docker-compose -f docker-compose.ssl.yml build --no-cache

# コンテナを起動（SSL証明書取得前）
log_step "コンテナを起動中（SSL証明書取得前）..."
docker-compose -f docker-compose.ssl.yml up -d nginx

# SSL証明書の取得
log_step "SSL証明書を取得中..."
sleep 10

# CertbotでSSL証明書を取得
docker-compose -f docker-compose.ssl.yml run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/html \
    --email $SSL_EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN_NAME

if [ $? -eq 0 ]; then
    log_info "SSL証明書の取得が完了しました"
else
    log_warn "SSL証明書の取得に失敗しました。手動で取得してください。"
    log_info "手動取得コマンド:"
    log_info "docker-compose -f docker-compose.ssl.yml run --rm certbot certonly --webroot --webroot-path=/var/www/html --email $SSL_EMAIL --agree-tos --no-eff-email -d $DOMAIN_NAME"
fi

# 全コンテナを起動
log_step "全コンテナを起動中..."
docker-compose -f docker-compose.ssl.yml up -d

# ヘルスチェック
log_step "ヘルスチェック中..."
sleep 45

# データベースの初期化確認
log_step "データベースの初期化を確認中..."
if docker-compose -f docker-compose.ssl.yml exec db pg_isready -U $POSTGRES_USER; then
    log_info "データベースが正常に起動しました"
else
    log_error "データベースの起動に失敗しました"
    docker-compose -f docker-compose.ssl.yml logs db
    exit 1
fi

# アプリケーションの起動確認
log_step "アプリケーションの起動を確認中..."
for i in {1..10}; do
    if curl -f https://$DOMAIN_NAME > /dev/null 2>&1; then
        log_info "Pleasanter が正常に起動しました"
        break
    else
        log_warn "アプリケーションの起動確認中... ($i/10)"
        sleep 10
    fi
    
    if [ $i -eq 10 ]; then
        log_error "アプリケーションの起動確認に失敗しました"
        docker-compose -f docker-compose.ssl.yml logs Implem.Pleasanter
        exit 1
    fi
done

# サービスの状態確認
log_step "サービスの状態を確認中..."
docker-compose -f docker-compose.ssl.yml ps

# SSL証明書の更新用cronジョブの設定
log_step "SSL証明書の自動更新を設定中..."
(crontab -l 2>/dev/null; echo "0 12 * * * cd $(pwd) && docker-compose -f docker-compose.ssl.yml run --rm certbot renew && docker-compose -f docker-compose.ssl.yml restart nginx") | crontab -

log_info "=========================================="
log_info "SSL対応デプロイメントが完了しました！"
log_info "=========================================="
log_info "Pleasanter にアクセス: https://$DOMAIN_NAME"
log_info "CodeDefiner にアクセス: https://$DOMAIN_NAME/codedefiner/"
log_info "=========================================="

# 監視コマンドの表示
log_info "監視コマンド:"
log_info "  docker-compose -f docker-compose.ssl.yml ps"
log_info "  docker-compose -f docker-compose.ssl.yml logs -f"
log_info "  docker-compose -f docker-compose.ssl.yml exec db psql -U $POSTGRES_USER -d $POSTGRES_DB" 