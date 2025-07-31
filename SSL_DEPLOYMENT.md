# Pleasanter SSL対応自動デプロイメントガイド

このリポジトリには、Pleasanter環境をSSL対応で全自動構築するためのスクリプトと設定ファイルが含まれています。

## 📋 前提条件

- Linux サーバー（Ubuntu 20.04+ または CentOS 7+ 推奨）
- 最低 4GB RAM、20GB ディスク容量
- インターネット接続
- ドメイン名（DNS設定済み）
- メールアドレス（SSL証明書用）

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
cp env.ssl.example .env

# 設定を編集
nano .env
```

**必須設定項目:**
```bash
# サーバー情報（変更してください）
SERVER_IP=162.43.9.32
DOMAIN_NAME=miura-training.xvps.jp
SSL_EMAIL=your-email@example.com

# データベースパスワード
POSTGRES_PASSWORD=your_secure_password_here
```

### 3. デプロイメントの実行

```bash
# SSL対応デプロイメントを実行
./deploy-ssl.sh
```

## 📁 ファイル構成

```
Implem.Pleasanter/
├── deploy-ssl.sh              # SSL対応デプロイスクリプト
├── docker-compose.ssl.yml     # SSL対応Docker Compose
├── env.ssl.example            # SSL対応環境変数テンプレート
├── nginx/
│   └── nginx-ssl.conf        # SSL対応Nginx設定
├── init-db/
│   └── 01-init.sql           # データベース初期化スクリプト
└── SSL_DEPLOYMENT.md         # このファイル
```

## 🔧 詳細設定

### 環境変数

`.env` ファイルで以下の設定が可能です：

```bash
# サーバー情報
SERVER_IP=your-server-ip
DOMAIN_NAME=your-domain.com
SSL_EMAIL=your-email@example.com

# データベース設定
POSTGRES_USER=pleasanter
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=pleasanter

# アプリケーション設定
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:80

# セキュリティ設定
Pleasanter_Authentication_Provider=Forms
Pleasanter_Authentication_Forms_RequireHttps=true
```

### DNS設定

デプロイ前に以下のDNS設定が必要です：

1. **Aレコード**: `your-domain.com` → `your-server-ip`
2. **CNAMEレコード**: `www.your-domain.com` → `your-domain.com`（オプション）

### SSL証明書

Let's Encryptを使用して自動的にSSL証明書を取得します：

- **自動取得**: デプロイ時に自動実行
- **自動更新**: 毎日12時に自動更新
- **有効期限**: 90日（自動更新により継続利用可能）

## 📊 監視とメンテナンス

### サービスの状態確認

```bash
# コンテナの状態確認
docker-compose -f docker-compose.ssl.yml ps

# ログの確認
docker-compose -f docker-compose.ssl.yml logs -f

# データベース接続
docker-compose -f docker-compose.ssl.yml exec db psql -U pleasanter -d pleasanter
```

### SSL証明書の管理

```bash
# 証明書の更新確認
docker-compose -f docker-compose.ssl.yml run --rm certbot certificates

# 手動更新
docker-compose -f docker-compose.ssl.yml run --rm certbot renew

# 更新後のNginx再起動
docker-compose -f docker-compose.ssl.yml restart nginx
```

### 自動監視

システムは5分ごとに自動監視されます：
- コンテナの状態
- ディスク使用量
- メモリ使用量
- SSL証明書の有効期限

## 🔒 セキュリティ

### 推奨設定

1. **ファイアウォール設定**
   ```bash
   # 必要なポートのみ開放
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 80/tcp    # HTTP
   sudo ufw allow 443/tcp   # HTTPS
   sudo ufw enable
   ```

2. **パスワード設定**
   - 強力なパスワードを使用
   - 定期的なパスワード変更

3. **SSL設定**
   - HSTSヘッダー有効
   - セキュリティヘッダー設定済み
   - 最新の暗号化プロトコル使用

## 🚨 トラブルシューティング

### よくある問題

1. **SSL証明書取得エラー**
   ```bash
   # DNS設定を確認
   nslookup your-domain.com
   
   # 手動で証明書取得
   docker-compose -f docker-compose.ssl.yml run --rm certbot certonly --webroot --webroot-path=/var/www/html --email your-email@example.com --agree-tos --no-eff-email -d your-domain.com
   ```

2. **コンテナが起動しない**
   ```bash
   # ログを確認
   docker-compose -f docker-compose.ssl.yml logs
   
   # イメージを再ビルド
   docker-compose -f docker-compose.ssl.yml build --no-cache
   ```

3. **HTTPSアクセスエラー**
   ```bash
   # SSL証明書の確認
   openssl s_client -connect your-domain.com:443 -servername your-domain.com
   
   # Nginx設定の確認
   docker-compose -f docker-compose.ssl.yml exec nginx nginx -t
   ```

### ログの場所

- アプリケーションログ: `/opt/pleasanter/logs/`
- Dockerログ: `docker-compose -f docker-compose.ssl.yml logs`
- Nginxログ: `docker-compose -f docker-compose.ssl.yml exec nginx tail -f /var/log/nginx/access.log`
- SSL証明書: `./nginx/letsencrypt/`

## 📞 サポート

問題が発生した場合は、以下の情報を収集してください：

1. エラーメッセージ
2. システム情報 (`uname -a`)
3. Docker バージョン (`docker --version`)
4. ログファイル
5. DNS設定確認結果

## 📝 更新履歴

- 2024-01-XX: SSL対応版リリース
  - Let's Encrypt自動証明書取得
  - HTTPS強制リダイレクト
  - セキュリティヘッダー設定
  - 自動証明書更新

## 📄 ライセンス

このプロジェクトは元のPleasanterライセンスに従います。 