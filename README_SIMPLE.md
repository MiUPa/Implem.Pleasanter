# Pleasanter シンプルHTTP環境

このディレクトリには、PleasanterをHTTPで動作させるための最小限の設定ファイルが含まれています。

## 特徴

- **シンプルな構成**: PostgreSQL + Pleasanter のみ
- **HTTPアクセス**: 8080番ポートでアクセス
- **SSLなし**: 証明書取得やNginx不要
- **最小限の依存関係**: 必要最小限のサービスのみ

## クイックスタート

### 1. デプロイメントの実行

```bash
# デプロイメントスクリプトを実行
./deploy-simple.sh
```

### 2. アクセス

デプロイメントが完了すると、以下のURLでアクセスできます：

- **Pleasanter**: http://localhost:8080
- **PostgreSQL**: localhost:5432

## ファイル構成

- `docker-compose.simple.yml`: シンプルなDocker Compose設定
- `deploy-simple.sh`: シンプルデプロイメントスクリプト

## 主な特徴

### 最小限の構成
- PostgreSQL: データベース
- Pleasanter: メインアプリケーション
- 環境変数: 直接Docker Composeファイルに記述

### ポートマッピング
- Pleasanter: 8080番ポート
- PostgreSQL: 5432番ポート

### 本番環境設定
- `ASPNETCORE_ENVIRONMENT=Production`
- データベース接続文字列: 直接指定

## 管理コマンド

### コンテナの状態確認
```bash
docker-compose -f docker-compose.simple.yml ps
```

### ログの確認
```bash
# 全サービスのログ
docker-compose -f docker-compose.simple.yml logs -f

# 特定サービスのログ
docker-compose -f docker-compose.simple.yml logs -f Implem.Pleasanter
```

### データベースへの接続
```bash
docker-compose -f docker-compose.simple.yml exec db psql -U pleasanter -d pleasanter
```

### コンテナの停止
```bash
docker-compose -f docker-compose.simple.yml down
```

### データの完全削除
```bash
docker-compose -f docker-compose.simple.yml down -v
```

## トラブルシューティング

### ポートが既に使用されている場合
```bash
# 使用中のポートを確認
lsof -i :8080
lsof -i :5432

# 必要に応じてプロセスを停止
kill -9 <PID>
```

### ビルドエラーの場合
```bash
# キャッシュをクリアして再ビルド
docker-compose -f docker-compose.simple.yml build --no-cache
```

### データベースエラーの場合
```bash
# データベースログを確認
docker-compose -f docker-compose.simple.yml logs db

# データベースに直接接続
docker-compose -f docker-compose.simple.yml exec db psql -U pleasanter -d pleasanter
```

## 他の環境との違い

| 項目 | シンプル環境 | ローカル環境 | 本番環境 |
|------|-------------|-------------|----------|
| SSL証明書 | なし | なし | Let's Encrypt |
| リバースプロキシ | なし | なし | Nginx |
| ポート | 8080 | 8080, 8081 | 80, 443 |
| CodeDefiner | なし | あり | あり |
| 環境変数 | 直接記述 | .envファイル | .envファイル |

## 注意事項

- この環境は開発・テスト用途のみ
- 本番データは使用しない
- セキュリティ設定は最小限
- 外部からのアクセスは想定していない 