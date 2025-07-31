#!/bin/bash

# サーバー環境初期セットアップスクリプト
# 使用方法: ./setup-server.sh

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

log_info "Pleasanter サーバー環境セットアップを開始します"

# OSの確認
log_step "OS情報を確認中..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    log_error "サポートされていないOSです: $OSTYPE"
    exit 1
fi

log_info "OS: $OS"

# パッケージマネージャーの更新
log_step "パッケージマネージャーを更新中..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update
elif command -v yum &> /dev/null; then
    sudo yum update -y
elif command -v brew &> /dev/null; then
    brew update
fi

# Docker のインストール
log_step "Docker をインストール中..."
if ! command -v docker &> /dev/null; then
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
    elif command -v brew &> /dev/null; then
        # macOS
        brew install --cask docker
    fi
    
    # Docker サービスを開始
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # ユーザーをdockerグループに追加
    sudo usermod -aG docker $USER
    log_warn "Docker グループにユーザーを追加しました。ログアウトして再ログインしてください。"
else
    log_info "Docker は既にインストールされています"
fi

# Docker Compose のインストール
log_step "Docker Compose をインストール中..."
if ! command -v docker-compose &> /dev/null; then
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        sudo apt-get install -y docker-compose-plugin
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        sudo yum install -y docker-compose-plugin
    elif command -v brew &> /dev/null; then
        # macOS
        brew install docker-compose
    fi
else
    log_info "Docker Compose は既にインストールされています"
fi

# ファイアウォールの設定
log_step "ファイアウォールを設定中..."
if command -v ufw &> /dev/null; then
    # Ubuntu/Debian
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 5432/tcp
    sudo ufw --force enable
elif command -v firewall-cmd &> /dev/null; then
    # CentOS/RHEL
    sudo firewall-cmd --permanent --add-port=22/tcp
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-port=5432/tcp
    sudo firewall-cmd --reload
fi

# 必要なディレクトリの作成
log_step "必要なディレクトリを作成中..."
mkdir -p /opt/pleasanter
mkdir -p /opt/pleasanter/data
mkdir -p /opt/pleasanter/logs
mkdir -p /opt/pleasanter/backups

# 環境変数ファイルの作成
log_step "環境変数ファイルを作成中..."
if [ ! -f ".env" ]; then
    cp env.example .env
    log_warn ".env ファイルを作成しました。パスワードを変更してください。"
else
    log_info ".env ファイルは既に存在します"
fi

# システムリソースの設定
log_step "システムリソースを設定中..."

# メモリ制限の設定
if [ -f "/etc/docker/daemon.json" ]; then
    log_info "Docker daemon.json は既に存在します"
else
    sudo mkdir -p /etc/docker
    echo '{
        "default-ulimits": {
            "nofile": {
                "Name": "nofile",
                "Hard": 64000,
                "Soft": 64000
            }
        }
    }' | sudo tee /etc/docker/daemon.json
    sudo systemctl restart docker
fi

# ログローテーションの設定
log_step "ログローテーションを設定中..."
if [ ! -f "/etc/logrotate.d/pleasanter" ]; then
    echo "/opt/pleasanter/logs/*.log {
        daily
        missingok
        rotate 30
        compress
        delaycompress
        notifempty
        create 644 root root
    }" | sudo tee /etc/logrotate.d/pleasanter
fi

# 監視スクリプトの作成
log_step "監視スクリプトを作成中..."
cat > /opt/pleasanter/monitor.sh << 'EOF'
#!/bin/bash
# Pleasanter 監視スクリプト

LOG_FILE="/opt/pleasanter/logs/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# コンテナの状態確認
if ! docker-compose -f /opt/pleasanter/docker-compose.prod.yml ps | grep -q "Up"; then
    echo "[$DATE] コンテナが停止しています。再起動を試行します。" >> $LOG_FILE
    cd /opt/pleasanter && docker-compose -f docker-compose.prod.yml up -d
fi

# ディスク使用量の確認
DISK_USAGE=$(df /opt/pleasanter | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "[$DATE] ディスク使用量が80%を超えています: ${DISK_USAGE}%" >> $LOG_FILE
fi

# メモリ使用量の確認
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ $MEMORY_USAGE -gt 80 ]; then
    echo "[$DATE] メモリ使用量が80%を超えています: ${MEMORY_USAGE}%" >> $LOG_FILE
fi
EOF

chmod +x /opt/pleasanter/monitor.sh

# cron ジョブの設定
log_step "cron ジョブを設定中..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/pleasanter/monitor.sh") | crontab -

log_info "=========================================="
log_info "サーバー環境セットアップが完了しました！"
log_info "=========================================="
log_info "次の手順:"
log_info "1. .env ファイルでパスワードを変更"
log_info "2. ./deploy-prod.sh を実行してデプロイ"
log_info "3. ログアウトして再ログイン（Dockerグループの変更を反映）"
log_info "==========================================" 