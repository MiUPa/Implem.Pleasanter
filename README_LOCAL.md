# Pleasanter ローカルテスト環境

このディレクトリには、Pleasanterをローカルでテストするための設定ファイルが含まれています。

## 前提条件

- Docker Desktop がインストールされていること
- 8GB以上のメモリが利用可能であること
- 10GB以上の空き容量があること

## クイックスタート

### 1. 環境変数ファイルの準備

```bash
# 環境変数ファイルをコピー
cp env.local.example .env

# 必要に応じて設定を編集
nano .env
```

### 2. ローカルデプロイメントの実行

```bash
# デプロイメントスクリプトを実行
./deploy-local.sh
```

### 3. アクセス

デプロイメントが完了すると、以下のURLでアクセスできます：

- **Pleasanter**: http://localhost:8080
- **CodeDefiner**: http://localhost:8081
- **PostgreSQL**: localhost:5432

## ファイル構成

- `docker-compose.local.yml`: ローカルテスト用のDocker Compose設定
- `env.local.example`: ローカルテスト用の環境変数テンプレート
- `deploy-local.sh`: ローカルデプロイメントスクリプト

## 主な特徴

### SSL証明書なし
- ローカルテストではSSL証明書の取得をスキップ
- HTTPでアクセス可能
- 開発環境として最適

### ポートマッピング
- Pleasanter: 8080番ポート
- CodeDefiner: 8081番ポート
- PostgreSQL: 5432番ポート

### 開発環境設定
- `ASPNETCORE_ENVIRONMENT=Development`
- HTTPS要求を無効化
- 詳細なログ出力

## 管理コマンド

### コンテナの状態確認
```bash
docker-compose -f docker-compose.local.yml ps
```

### ログの確認
```bash
# 全サービスのログ
docker-compose -f docker-compose.local.yml logs -f

# 特定サービスのログ
docker-compose -f docker-compose.local.yml logs -f Implem.Pleasanter
```

### データベースへの接続
```bash
docker-compose -f docker-compose.local.yml exec db psql -U pleasanter -d pleasanter
```

### コンテナの停止
```bash
docker-compose -f docker-compose.local.yml down
```

### データの完全削除
```bash
docker-compose -f docker-compose.local.yml down -v
```

## トラブルシューティング

### ポートが既に使用されている場合
```bash
# 使用中のポートを確認
lsof -i :8080
lsof -i :8081
lsof -i :5432

# 必要に応じてプロセスを停止
kill -9 <PID>
```

### メモリ不足の場合
- Docker Desktopのメモリ設定を8GB以上に増やす
- 不要なコンテナを停止する

### ビルドエラーの場合
```bash
# キャッシュをクリアして再ビルド
docker-compose -f docker-compose.local.yml build --no-cache
```

## 本番環境との違い

| 項目 | ローカル環境 | 本番環境 |
|------|-------------|----------|
| SSL証明書 | なし（HTTP） | Let's Encrypt（HTTPS） |
| 環境 | Development | Production |
| ポート | 8080, 8081 | 80, 443 |
| リバースプロキシ | なし | Nginx |
| ドメイン | localhost | 実際のドメイン |

## 注意事項

- ローカル環境は開発・テスト用途のみ
- 本番データは使用しない
- 定期的にコンテナを再起動してメモリをクリア
- 長時間使用する場合は定期的に `docker system prune` を実行 