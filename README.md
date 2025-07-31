# Pleasanter自動デプロイ環境

このリポジトリは、Pleasanterを全自動でサーバーに構築するための環境です。

## 前提条件

- Linuxサーバー（Ubuntu 20.04以降推奨）
- rootまたはsudo権限を持つユーザー
- インターネット接続

## クイックスタート

1. リポジトリをクローンします：

```bash
git clone https://github.com/MiUPa/Implem.Pleasanter.git
cd Implem.Pleasanter
git checkout auto-deploy-setup
```

2. 環境設定ファイルを準備します：

```bash
cp .env.sample .env
```

3. `.env`ファイルを必要に応じて編集します：

```bash
nano .env
```

4. デプロイスクリプトを実行します：

```bash
chmod +x deploy.sh
sudo ./deploy.sh
```

5. ブラウザで`https://サーバーのドメイン名`または`https://サーバーのIPアドレス`にアクセスします。

## 環境設定

`.env`ファイルで以下の設定を変更できます：

- `POSTGRES_USER`: PostgreSQLのユーザー名
- `POSTGRES_PASSWORD`: PostgreSQLのパスワード
- `POSTGRES_DB`: PostgreSQLのデータベース名
- `SERVER_NAME`: サーバーのドメイン名またはIPアドレス（SSL証明書に使用）
- `PLEASANTER_PORT`: Pleasanterの内部ポート番号（通常は変更不要）
- `TIMEZONE`: タイムゾーン（デフォルト: Asia/Tokyo）
- `DEFAULT_LANGUAGE`: デフォルト言語（デフォルト: ja）

## SSL証明書

デプロイ時に自己署名SSL証明書が自動的に生成されます。本番環境では、Let's Encryptなどの正式な証明書を使用することをお勧めします。

## データの永続化

以下のDockerボリュームが作成され、データが永続化されます：

- `pleasanter_postgres_data`: PostgreSQLデータベースのデータ
- `pleasanter_app_data`: Pleasanterのアプリケーションデータ

## バックアップ方法

データベースのバックアップ：

```bash
docker exec postgresql pg_dump -U postgres pleasanter > backup_$(date +%Y%m%d).sql
```

アプリケーションデータのバックアップ：

```bash
docker cp pleasanter:/app/App_Data ./backup_app_data_$(date +%Y%m%d)
```

## トラブルシューティング

### コンテナが起動しない場合

ログを確認します：

```bash
docker-compose logs
```

### データベース接続エラーの場合

`.env`ファイルの接続文字列を確認します。

### SSL証明書の警告が表示される場合

自己署名証明書を使用しているため、ブラウザで警告が表示されます。これは正常な動作です。本番環境では、Let's Encryptなどの正式な証明書を使用してください。

## メンテナンス

### コンテナの再起動

```bash
docker-compose restart
```

### アップデート

```bash
git pull
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## ライセンス

このプロジェクトは、元のPleasanterと同じライセンスに従います。
