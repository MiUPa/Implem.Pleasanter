-- Pleasanter データベース初期化スクリプト

-- データベースが存在しない場合は作成
-- 注意: PostgreSQLでは、コンテナ起動時に自動的にデータベースが作成されるため、
-- このスクリプトは主に追加の設定や初期データの挿入に使用します

-- 必要な拡張機能の有効化
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ログ出力
DO $$
BEGIN
    RAISE NOTICE 'Pleasanter データベース初期化が完了しました';
END $$; 