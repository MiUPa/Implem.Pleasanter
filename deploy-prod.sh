#!/bin/bash

# Pleasanter 本番環境自動デプロイメントスクリプト
# 使用方法: ./deploy-prod.sh [サーバーIP]

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

# 引数からサーバーIPを取得
SERVER_IP=${1:-"localhost"}

# 環境変数ファイルの確認
if [ ! -f ".env" ]; then
    log_error ".env ファイルが見つかりません。env.example をコピーして設定してください。"
    exit 1
fi

# 環境変数の読み込み
source .env

log_info "Pleasanter 本番環境デプロイメントを開始します"
log_info "対象サーバー: $SERVER_IP"

# 前提条件の確認
log_step "前提条件の確認中..."

# Docker と Docker Compose の確認
if ! command -v docker &> /dev/null; then
    log_error "Docker がインストールされていません。"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose がインストールされていません。"
    exit 1
fi

# 必要なディレクトリの作成
log_step "必要なディレクトリを作成中..."
mkdir -p nginx/ssl
mkdir -p logs

# バックアップの作成
log_step "既存データのバックアップを作成中..."
if [ -d "data" ]; then
    tar -czf "backup-$(date +%Y%m%d-%H%M%S).tar.gz" data/
    log_info "バックアップが作成されました"
fi

# 既存のコンテナを停止
log_step "既存のコンテナを停止中..."
docker-compose -f docker-compose.prod.yml down || true

# イメージを再ビルド
log_step "Docker イメージをビルド中..."
docker-compose -f docker-compose.prod.yml build --no-cache

# コンテナを起動
log_step "コンテナを起動中..."
docker-compose -f docker-compose.prod.yml up -d

# ヘルスチェック
log_step "ヘルスチェック中..."
sleep 45

# データベースの初期化確認
log_step "データベースの初期化を確認中..."
if docker-compose -f docker-compose.prod.yml exec db pg_isready -U $POSTGRES_USER; then
    log_info "データベースが正常に起動しました"
else
    log_error "データベースの起動に失敗しました"
    docker-compose -f docker-compose.prod.yml logs db
    exit 1
fi

# アプリケーションの起動確認
log_step "アプリケーションの起動を確認中..."
for i in {1..10}; do
    if curl -f http://$SERVER_IP:80 > /dev/null 2>&1; then
        log_info "Pleasanter が正常に起動しました"
        break
    else
        log_warn "アプリケーションの起動確認中... ($i/10)"
        sleep 10
    fi
    
    if [ $i -eq 10 ]; then
        log_error "アプリケーションの起動確認に失敗しました"
        docker-compose -f docker-compose.prod.yml logs Implem.Pleasanter
        exit 1
    fi
done

# サービスの状態確認
log_step "サービスの状態を確認中..."
docker-compose -f docker-compose.prod.yml ps

# ログの確認
log_step "ログを確認中..."
docker-compose -f docker-compose.prod.yml logs --tail=20

log_info "=========================================="
log_info "デプロイメントが完了しました！"
log_info "=========================================="
log_info "Pleasanter にアクセス: http://$SERVER_IP:80"
log_info "CodeDefiner にアクセス: http://$SERVER_IP:8080"
log_info "データベースポート: $SERVER_IP:5432"
log_info "=========================================="

# 監視コマンドの表示
log_info "監視コマンド:"
log_info "  docker-compose -f docker-compose.prod.yml ps"
log_info "  docker-compose -f docker-compose.prod.yml logs -f"
log_info "  docker-compose -f docker-compose.prod.yml exec db psql -U $POSTGRES_USER -d $POSTGRES_DB" 