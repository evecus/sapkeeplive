FROM --platform=$TARGETPLATFORM ubuntu:latest

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    curl wget ca-certificates tzdata cron \
    && rm -rf /var/lib/apt/lists/*

# 设置上海时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

# 安装 Cloud Foundry CLI
RUN if [ "$TARGETARCH" = "amd64" ]; then ARCH="x86-64"; else ARCH="arm64"; fi && \
    LATEST_TAG=$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    LATEST_VERSION=${LATEST_TAG#v} && \
    wget -O /tmp/cf.deb "https://github.com/cloudfoundry/cli/releases/download/${LATEST_TAG}/cf8-cli-installer_${LATEST_VERSION}_${ARCH}.deb" && \
    dpkg -i /tmp/cf.deb && rm /tmp/cf.deb

# 复制脚本
COPY sap-keep.sh /usr/local/bin/sap-keep.sh
RUN chmod +x /usr/local/bin/sap-keep.sh

# 写入 Cron 任务：每天 8:30 执行
# 使用 . /etc/environment 确保脚本能读取到 docker run -e 传入的环境变量
RUN echo "30 8 * * * . /etc/environment; /bin/bash /usr/local/bin/sap-keep.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/sap-cron
RUN chmod 0644 /etc/cron.d/sap-cron && crontab /etc/cron.d/sap-cron

# 创建日志文件
RUN touch /var/log/cron.log

# 启动 cron 并实时查看日志
CMD ["sh", "-c", "printenv > /etc/environment && cron && tail -f /var/log/cron.log"]
