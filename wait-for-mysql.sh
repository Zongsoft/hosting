#!/bin/sh
set -e

echo "Waiting for MySQL to be ready at $MYSQL_HOST:$MYSQL_PORT..."

# 使用循环来等待 MySQL 端口可用，超时设置可酌情添加
while ! nc -z $MYSQL_HOST $MYSQL_PORT; do
  sleep 1
done

echo "MySQL is up!"

# 额外的短暂等待，确保 MySQL 服务完全初始化（例如完成初始数据库创建等）
sleep 5

# 安装 netcat (nc) 命令（如果基础镜像里没有的话）
# 同样根据包管理器安装
if ! command -v nc > /dev/null 2>&1; then
    echo "Installing netcat to check port availability..."
    case "$PKG_MANAGER" in
        apt )
            apt-get update && apt-get install -y --no-install-recommends netcat-openbsd && apt-get clean && rm -rf /var/lib/apt/lists/*
            ;;
        apk )
            apk add --no-cache netcat-openbsd
            ;;
        yum )
            yum install -y nc
            ;;
        microdnf )
            microdnf install -y nc
            ;;
        * )
            echo "ERROR: Cannot install netcat. Unsupported package manager: $PKG_MANAGER"
            exit 1
            ;;
    esac
fi

echo "Cloning the administratives repository..."
# 克隆仓库，可以添加重试逻辑或特定分支/标签检出
git clone https://github.com/Zongsoft/administratives.git /repository || { echo "Git clone failed. Exiting."; exit 1; }

cd /repository/database

# 定义需要执行的 SQL 文件列表，确保正确的顺序
sql_files=(
    "Administratives-China-Tables(mysql).sql"
    "Administratives-China(Province-City-District).sql"
    "Administratives-China(Street)-0.sql"
    "Administratives-China(Street)-1.sql"
    "Administratives-China(Street)-2.sql"
    "Administratives-China(Street)-3.sql"
    "Administratives-China(Street)-4.sql"
    "Administratives-China(Street)-5.sql"
    "Administratives-China(Street)-6.sql"
    "Administratives-China(Street)-7.sql"
    "Administratives-China(Street)-8.sql"
    "Administratives-China(Street)-9.sql"
)

# 依次执行每个 SQL 文件
for sql_file in "${sql_files[@]}"; do
    if [ -f "$sql_file" ]; then
        echo "Executing $sql_file..."
        # 使用 mysql 命令行客户端执行 SQL 文件
        mysql -h $MYSQL_HOST -P $MYSQL_PORT -u root -p$MYSQL_ROOT_PASSWORD < "$sql_file" || { echo "Error executing $sql_file. Check logs above. Exiting."; exit 1; }
    else
        echo "Warning: File $sql_file not found, skipping."
    fi
done

echo "All specified SQL files have been processed successfully."