#!/bin/bash

# Pleasanter ローカルテスト用デプロイメントスクリプト
# 使用方法: ./deploy-local.sh

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
    log_warn ".env ファイルが見つかりません。env.local.example をコピーして設定してください。"
    if [ -f "env.local.example" ]; then
        log_info "env.local.example を .env にコピーします..."
        cp env.local.example .env
        log_info ".env ファイルが作成されました。必要に応じて設定を変更してください。"
    else
        log_error "env.local.example ファイルも見つかりません。"
        exit 1
    fi
fi

# 環境変数の読み込み
source .env

log_info "Pleasanter ローカルテストデプロイメントを開始します"

# 前提条件の確認
log_step "前提条件の確認中..."

# Docker の確認
if ! command -v docker &> /dev/null; then
    log_error "Docker がインストールされていません。Docker Desktop をインストールしてください。"
    exit 1
fi

# Docker Compose の確認
if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose がインストールされていません。Docker Desktop をインストールしてください。"
    exit 1
fi

log_info "Docker と Docker Compose は正常にインストールされています"

# 必要なディレクトリの作成
log_step "必要なディレクトリを作成中..."
mkdir -p logs

# 既存のコンテナを停止
log_step "既存のコンテナを停止中..."
docker-compose -f docker-compose.local.yml down || true

# イメージを再ビルド
log_step "Docker イメージをビルド中..."
docker-compose -f docker-compose.local.yml build --no-cache

# コンテナを起動
log_step "コンテナを起動中..."
docker-compose -f docker-compose.local.yml up -d

# ヘルスチェック
log_step "ヘルスチェック中..."
sleep 30

# データベースの初期化確認
log_step "データベースの初期化を確認中..."
if docker-compose -f docker-compose.local.yml exec db pg_isready -U $POSTGRES_USER; then
    log_info "データベースが正常に起動しました"
else
    log_error "データベースの起動に失敗しました"
    docker-compose -f docker-compose.local.yml logs db
    exit 1
fi

# アプリケーションの起動確認
log_step "アプリケーションの起動を確認中..."
for i in {1..10}; do
    if curl -f http://localhost:8080 > /dev/null 2>&1; then
        log_info "Pleasanter が正常に起動しました"
        break
    else
        log_warn "アプリケーションの起動確認中... ($i/10)"
        sleep 10
    fi
    
    if [ $i -eq 10 ]; then
        log_error "アプリケーションの起動確認に失敗しました"
        docker-compose -f docker-compose.local.yml logs Implem.Pleasanter
        exit 1
    fi
done

# CodeDefinerの起動確認
log_step "CodeDefinerの起動を確認中..."
for i in {1..5}; do
    if curl -f http://localhost:8081 > /dev/null 2>&1; then
        log_info "CodeDefiner が正常に起動しました"
        break
    else
        log_warn "CodeDefinerの起動確認中... ($i/5)"
        sleep 5
    fi
    
    if [ $i -eq 5 ]; then
        log_warn "CodeDefinerの起動確認に失敗しました（オプション機能のため続行します）"
        docker-compose -f docker-compose.local.yml logs Implem.CodeDefiner
    fi
done

# サービスの状態確認
log_step "サービスの状態を確認中..."
docker-compose -f docker-compose.local.yml ps

log_info "=========================================="
log_info "ローカルテストデプロイメントが完了しました！"
log_info "=========================================="
log_info "Pleasanter にアクセス: http://localhost:8080"
log_info "CodeDefiner にアクセス: http://localhost:8081"
log_info "PostgreSQL にアクセス: localhost:5432"
log_info "=========================================="

# 監視コマンドの表示
log_info "監視コマンド:"
log_info "  docker-compose -f docker-compose.local.yml ps"
log_info "  docker-compose -f docker-compose.local.yml logs -f"
log_info "  docker-compose -f docker-compose.local.yml exec db psql -U $POSTGRES_USER -d $POSTGRES_DB"

# 停止コマンドの表示
log_info "停止コマンド:"
log_info "  docker-compose -f docker-compose.local.yml down" 