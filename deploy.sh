#!/bin/bash

# Pleasanter 自動デプロイメントスクリプト
# 使用方法: ./deploy.sh [環境名]

set -e

# 色付きログ出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 環境変数ファイルの確認
if [ ! -f ".env" ]; then
    log_error ".env ファイルが見つかりません。env.example をコピーして設定してください。"
    exit 1
fi

# 環境変数の読み込み
source .env

# 引数から環境名を取得（デフォルトは production）
ENVIRONMENT=${1:-production}

log_info "Pleasanter 自動デプロイメントを開始します (環境: $ENVIRONMENT)"

# Docker と Docker Compose の確認
if ! command -v docker &> /dev/null; then
    log_error "Docker がインストールされていません。"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose がインストールされていません。"
    exit 1
fi

log_info "Docker と Docker Compose の確認完了"

# 既存のコンテナを停止
log_info "既存のコンテナを停止中..."
docker-compose down

# イメージを再ビルド
log_info "Docker イメージをビルド中..."
docker-compose build --no-cache

# コンテナを起動
log_info "コンテナを起動中..."
docker-compose up -d

# ヘルスチェック
log_info "ヘルスチェック中..."
sleep 30

# データベースの初期化確認
log_info "データベースの初期化を確認中..."
if docker-compose exec db pg_isready -U $POSTGRES_USER; then
    log_info "データベースが正常に起動しました"
else
    log_error "データベースの起動に失敗しました"
    exit 1
fi

# アプリケーションの起動確認
log_info "アプリケーションの起動を確認中..."
if curl -f http://localhost:80 > /dev/null 2>&1; then
    log_info "Pleasanter が正常に起動しました"
else
    log_warn "アプリケーションの起動確認に失敗しました。しばらく待ってから再確認してください。"
fi

log_info "デプロイメントが完了しました！"
log_info "Pleasanter にアクセス: http://localhost:80"
log_info "CodeDefiner にアクセス: http://localhost:8080 (設定されている場合)" 