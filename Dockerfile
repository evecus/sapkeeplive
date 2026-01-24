# 使用多架构支持的基础镜像
FROM --platform=$TARGETPLATFORM ubuntu:latest

# 构建时传入架构参数
ARG TARGETARCH

# 安装运行环境
RUN apt-get update && apt-get install -y \
    curl wget ca-certificates tzdata cron \
    && rm -rf /var/lib/apt/lists/*

# 设置上海时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

# 根据架构安装对应的 CF CLI
RUN if [ "$TARGETARCH" = "amd64" ]; then ARCH="x86-64"; else ARCH="arm64"; fi && \
    LATEST_TAG=$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    LATEST_VERSION=${LATEST_TAG#v} && \
    wget -O /tmp/cf.deb "https://github.com/cloudfoundry/cli/releases/download/${LATEST_TAG}/cf8-cli-installer_${LATEST_VERSION}_${ARCH}.deb" && \
    dpkg -i /tmp/cf.deb && rm /tmp/cf.deb

# 脚本与任务配置
COPY keep_sap.sh /usr/local/bin/keep_sap.sh
RUN chmod +x /usr/local/bin/keep_sap.sh

# 关键：设置 Cron 任务并引用环境变量文件
RUN echo "*/2 8-9 * * * . /etc/environment; /bin/bash /usr/local/bin/keep_sap.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/sap-cron && \
    chmod 0644 /etc/cron.d/sap-cron

# 启动脚本：导出环境变量 -> 启动 Cron -> 持续查看日志
CMD ["sh", "-c", "printenv | grep -E 'CF_|URLS' > /etc/environment && cron && tail -f /var/log/cron.log"]
