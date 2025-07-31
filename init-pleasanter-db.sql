-- Pleasanter データベース初期化スクリプト
-- 基本的なテーブル構造を作成

-- Tenants テーブル
CREATE TABLE IF NOT EXISTS "Tenants" (
    "TenantId" SERIAL PRIMARY KEY,
    "Title" VARCHAR(255),
    "ContractSettings" TEXT,
    "ContractDeadline" TIMESTAMP,
    "LogoType" VARCHAR(50),
    "DisableAllUsersPermission" BOOLEAN DEFAULT FALSE,
    "DisableApi" BOOLEAN DEFAULT FALSE,
    "AllowExtensionsApi" BOOLEAN DEFAULT FALSE,
    "DisableStartGuide" BOOLEAN DEFAULT FALSE,
    "HtmlTitleTop" VARCHAR(255),
    "HtmlTitleSite" VARCHAR(255),
    "HtmlTitleRecord" VARCHAR(255),
    "TopStyle" TEXT,
    "TopScript" TEXT,
    "Theme" VARCHAR(50),
    "Creator" INTEGER,
    "Updator" INTEGER,
    "CreatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SysLogs テーブル
CREATE TABLE IF NOT EXISTS "SysLogs" (
    "SysLogId" SERIAL PRIMARY KEY,
    "MachineName" VARCHAR(255),
    "ServiceName" VARCHAR(255),
    "Application" VARCHAR(255),
    "Class" VARCHAR(255),
    "Method" VARCHAR(255),
    "AssemblyVersion" VARCHAR(255),
    "Comments" TEXT,
    "Creator" INTEGER,
    "Updator" INTEGER,
    "CreatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sessions テーブル
CREATE TABLE IF NOT EXISTS "Sessions" (
    "SessionId" SERIAL PRIMARY KEY,
    "SessionGuid" VARCHAR(255),
    "Key" VARCHAR(255),
    "Value" TEXT,
    "Page" VARCHAR(255),
    "UserArea" BOOLEAN DEFAULT FALSE,
    "Creator" INTEGER,
    "Updator" INTEGER,
    "CreatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users テーブル
CREATE TABLE IF NOT EXISTS "Users" (
    "UserId" SERIAL PRIMARY KEY,
    "LoginId" VARCHAR(255) UNIQUE,
    "Name" VARCHAR(255),
    "UserCode" VARCHAR(255),
    "Password" VARCHAR(255),
    "PasswordExpirationTime" TIMESTAMP,
    "PasswordChangeTime" TIMESTAMP,
    "PasswordChangeHistory" TEXT,
    "PasswordValidation" BOOLEAN DEFAULT TRUE,
    "Disabled" BOOLEAN DEFAULT FALSE,
    "Lockout" BOOLEAN DEFAULT FALSE,
    "LockoutCounter" INTEGER DEFAULT 0,
    "LastLoginTime" TIMESTAMP,
    "LastPasswordChangeTime" TIMESTAMP,
    "PasswordExpired" BOOLEAN DEFAULT FALSE,
    "Creator" INTEGER,
    "Updator" INTEGER,
    "CreatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Depts テーブル
CREATE TABLE IF NOT EXISTS "Depts" (
    "DeptId" SERIAL PRIMARY KEY,
    "DeptCode" VARCHAR(255),
    "DeptName" VARCHAR(255),
    "ParentId" INTEGER,
    "Creator" INTEGER,
    "Updator" INTEGER,
    "CreatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Groups テーブル
CREATE TABLE IF NOT EXISTS "Groups" (
    "GroupId" SERIAL PRIMARY KEY,
    "GroupName" VARCHAR(255),
    "GroupCode" VARCHAR(255),
    "Body" TEXT,
    "Creator" INTEGER,
    "Updator" INTEGER,
    "CreatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 初期データの挿入
INSERT INTO "Tenants" ("TenantId", "Title", "Creator", "Updator") 
VALUES (1, 'Default Tenant', 1, 1) 
ON CONFLICT ("TenantId") DO NOTHING;

INSERT INTO "Users" ("UserId", "LoginId", "Name", "UserCode", "Password", "Creator", "Updator") 
VALUES (1, 'admin', 'Administrator', 'ADMIN', 'admin', 1, 1) 
ON CONFLICT ("UserId") DO NOTHING;

INSERT INTO "Depts" ("DeptId", "DeptCode", "DeptName", "Creator", "Updator") 
VALUES (1, 'DEPT001', 'Default Department', 1, 1) 
ON CONFLICT ("DeptId") DO NOTHING;

-- インデックスの作成
CREATE INDEX IF NOT EXISTS "IX_SysLogs_CreatedTime" ON "SysLogs" ("CreatedTime");
CREATE INDEX IF NOT EXISTS "IX_Sessions_SessionGuid" ON "Sessions" ("SessionGuid");
CREATE INDEX IF NOT EXISTS "IX_Users_LoginId" ON "Users" ("LoginId");
CREATE INDEX IF NOT EXISTS "IX_Depts_DeptCode" ON "Depts" ("DeptCode"); 