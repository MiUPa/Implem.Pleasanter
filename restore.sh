#!/bin/bash
set -e

# Pleasanterリストアスクリプト
echo "Pleasanterリストアを開始します..."

# バックアップファイルの確認
if [ -z "$1" ]; then
  echo "使用方法: $0 <バックアップファイル.tar.gz>"
  exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
  echo "バックアップファイル $BACKUP_FILE が見つかりません。"
  exit 1
fi

# 環境変数の読み込み
if [ -f .env ]; then
  source .env
else
  echo "環境設定ファイル(.env)が見つかりません。"
  exit 1
fi

# 一時ディレクトリの作成
TEMP_DIR="./temp_restore"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

# バックアップの展開
echo "バックアップを展開しています..."
tar -xzf $BACKUP_FILE -C $TEMP_DIR

# バックアップディレクトリの特定
BACKUP_DIR=$(find $TEMP_DIR -type d -name "20*" | head -1)

if [ -z "$BACKUP_DIR" ]; then
  echo "バックアップディレクトリが見つかりません。"
  exit 1
fi

# コンテナの停止
echo "コンテナを停止しています..."
docker-compose down

# データベースの復元
echo "データベースを復元しています..."
docker-compose up -d db
sleep 10  # データベースの起動を待つ

# データベースの復元
echo "PostgreSQLデータベースを復元しています..."
cat $BACKUP_DIR/postgres.sql | docker exec -i postgresql psql -U $POSTGRES_USER postgres
cat $BACKUP_DIR/pleasanter.sql | docker exec -i postgresql psql -U $POSTGRES_USER pleasanter

# アプリケーションデータの復元
echo "アプリケーションデータを復元しています..."
docker-compose up -d pleasanter
sleep 5  # コンテナの起動を待つ
docker cp $BACKUP_DIR/app_data/. pleasanter:/app/App_Data/

# コンテナの再起動
echo "コンテナを再起動しています..."
docker-compose restart

# 一時ディレクトリの削除
rm -rf $TEMP_DIR

echo "リストアが完了しました。"