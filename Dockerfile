FROM mysql:8.4.6

# 设置一个构建参数，允许在构建时指定目标平台（如果需要）
ARG TARGETOS
ARG TARGETARCH
# 设置一个构建参数，允许指定基础镜像的变体（例如 -alpine, -bullseye等），默认为空（即使用默认的debian系）
ARG BASE_VARIANT=""

# 设置环境变量，用于后续脚本中判断包管理器
ENV PKG_MANAGER="" \
    MYSQL_ROOT_PASSWORD="mysql" \
    MYSQL_HOST="127.0.0.1" \
    MYSQL_PORT="3306"

# 安装 git 及其他可能需要的工具，并尝试适配不同基础镜像
RUN set -eux; \
    # 检测包管理器
    if command -v apt-get > /dev/null 2>&1; then \
        PKG_MANAGER="apt"; \
        apt-get update; \
        apt-get install -y --no-install-recommends git; \
        apt-get clean; \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    elif command -v apk > /dev/null 2>&1; then \
        PKG_MANAGER="apk"; \
        apk add --no-cache git; \
    elif command -v yum > /dev/null 2>&1; then \
        PKG_MANAGER="yum"; \
        yum install -y git; \
        yum clean all; \
    elif command -v microdnf > /dev/null 2>&1; then \
        PKG_MANAGER="microdnf"; \
        microdnf install -y git; \
        microdnf clean all; \
    else \
        echo "ERROR: Cannot determine package manager (apt/apk/yum/microdnf) in the base image."; \
        exit 1; \
    fi

# 设置工作目录
WORKDIR /scripts

# 将启动脚本复制到镜像中
COPY wait-for-mysql.sh /scripts/wait-for-mysql.sh
RUN chmod +x /scripts/wait-for-mysql.sh

# 设置默认的入口命令，以便在容器运行时自动执行脚本
ENTRYPOINT ["/scripts/wait-for-mysql.sh"]
