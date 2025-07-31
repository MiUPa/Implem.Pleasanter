#!/bin/bash
set -e

# Pleasanterバックアップスクリプト
echo "Pleasanterバックアップを開始します..."

# バックアップディレクトリの作成
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# 環境変数の読み込み
if [ -f .env ]; then
  source .env
else
  echo "環境設定ファイル(.env)が見つかりません。"
  exit 1
fi

# データベースのバックアップ
echo "データベースのバックアップを作成しています..."
docker exec postgresql pg_dump -U $POSTGRES_USER postgres > $BACKUP_DIR/postgres.sql
docker exec postgresql pg_dump -U $POSTGRES_USER pleasanter > $BACKUP_DIR/pleasanter.sql

# アプリケーションデータのバックアップ
echo "アプリケーションデータのバックアップを作成しています..."
mkdir -p $BACKUP_DIR/app_data
docker cp pleasanter:/app/App_Data/. $BACKUP_DIR/app_data/

# バックアップの圧縮
echo "バックアップを圧縮しています..."
tar -czf $BACKUP_DIR.tar.gz -C $(dirname $BACKUP_DIR) $(basename $BACKUP_DIR)

# 古いバックアップの削除（30日以上前のもの）
find ./backups -name "*.tar.gz" -type f -mtime +30 -delete

echo "バックアップが完了しました: $BACKUP_DIR.tar.gz"