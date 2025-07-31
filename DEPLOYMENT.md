# Pleasanter 自動デプロイメントガイド

このリポジトリには、Pleasanter環境をサーバーに全自動で構築するためのスクリプトと設定ファイルが含まれています。

## 📋 前提条件

- Linux サーバー（Ubuntu 20.04+ または CentOS 7+ 推奨）
- 最低 4GB RAM、20GB ディスク容量
- インターネット接続

## 🚀 クイックスタート

### 1. サーバー環境のセットアップ

```bash
# リポジトリをクローン
git clone https://github.com/MiUPa/Implem.Pleasanter.git
cd Implem.Pleasanter

# サーバー環境をセットアップ
sudo ./setup-server.sh
```

### 2. 環境変数の設定

```bash
# 環境変数ファイルをコピー
cp env.example .env

# パスワードを変更
nano .env
```

重要な設定項目：
- `POSTGRES_PASSWORD`: データベースのパスワード
- `Implem_Pleasanter_Rds_PostgreSQL_*ConnectionString`: 接続文字列のパスワード

### 3. デプロイメントの実行

```bash
# 本番環境にデプロイ
./deploy-prod.sh [サーバーIP]
```

## 📁 ファイル構成

```
Implem.Pleasanter/
├── deploy.sh              # 開発環境用デプロイスクリプト
├── deploy-prod.sh         # 本番環境用デプロイスクリプト
├── setup-server.sh        # サーバー環境セットアップスクリプト
├── docker-compose.yml     # 開発環境用Docker Compose
├── docker-compose.prod.yml # 本番環境用Docker Compose
├── env.example            # 環境変数テンプレート
├── nginx/
│   └── nginx.conf        # Nginx設定ファイル
├── init-db/
│   └── 01-init.sql       # データベース初期化スクリプト
└── DEPLOYMENT.md         # このファイル
```

## 🔧 詳細設定

### 環境変数

`.env` ファイルで以下の設定が可能です：

```bash
# データベース設定
POSTGRES_USER=pleasanter
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=pleasanter

# アプリケーション設定
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:80

# セキュリティ設定
Pleasanter_Authentication_Provider=Forms
Pleasanter_Authentication_Forms_RequireHttps=false
```

### SSL証明書の設定

本番環境でHTTPSを使用する場合：

1. SSL証明書を `nginx/ssl/` ディレクトリに配置
2. `nginx/nginx.conf` のコメントアウトを解除
3. `docker-compose.prod.yml` でポート443を有効化

### バックアップ

自動バックアップは以下の場所に保存されます：
- データベース: `/opt/pleasanter/backups/`
- ログ: `/opt/pleasanter/logs/`

## 📊 監視とメンテナンス

### サービスの状態確認

```bash
# コンテナの状態確認
docker-compose -f docker-compose.prod.yml ps

# ログの確認
docker-compose -f docker-compose.prod.yml logs -f

# データベース接続
docker-compose -f docker-compose.prod.yml exec db psql -U pleasanter -d pleasanter
```

### 自動監視

システムは5分ごとに自動監視されます：
- コンテナの状態
- ディスク使用量
- メモリ使用量

### ログローテーション

ログは30日間保持され、自動的に圧縮されます。

## 🔒 セキュリティ

### 推奨設定

1. **ファイアウォール設定**
   - ポート22 (SSH)
   - ポート80 (HTTP)
   - ポート443 (HTTPS)
   - ポート5432 (PostgreSQL) - 必要に応じて

2. **パスワード設定**
   - 強力なパスワードを使用
   - 定期的なパスワード変更

3. **SSL証明書**
   - Let's Encrypt または商用証明書を使用
   - 証明書の自動更新設定

## 🚨 トラブルシューティング

### よくある問題

1. **コンテナが起動しない**
   ```bash
   # ログを確認
   docker-compose -f docker-compose.prod.yml logs
   
   # イメージを再ビルド
   docker-compose -f docker-compose.prod.yml build --no-cache
   ```

2. **データベース接続エラー**
   ```bash
   # データベースの状態確認
   docker-compose -f docker-compose.prod.yml exec db pg_isready
   
   # 環境変数の確認
   cat .env
   ```

3. **メモリ不足**
   ```bash
   # システムリソースの確認
   free -h
   df -h
   
   # 不要なコンテナの削除
   docker system prune -a
   ```

### ログの場所

- アプリケーションログ: `/opt/pleasanter/logs/`
- Dockerログ: `docker-compose -f docker-compose.prod.yml logs`
- システムログ: `/var/log/syslog`

## 📞 サポート

問題が発生した場合は、以下の情報を収集してください：

1. エラーメッセージ
2. システム情報 (`uname -a`)
3. Docker バージョン (`docker --version`)
4. ログファイル

## 📝 更新履歴

- 2024-01-XX: 初回リリース
  - 自動デプロイメントスクリプト
  - サーバー環境セットアップ
  - 監視機能

## 📄 ライセンス

このプロジェクトは元のPleasanterライセンスに従います。 