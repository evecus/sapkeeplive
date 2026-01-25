FROM --platform=$TARGETPLATFORM ubuntu:latest

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    curl wget ca-certificates tzdata cron \
    [span_1](start_span)&& rm -rf /var/lib/apt/lists/*[span_1](end_span)

# [span_2](start_span)设置时区为上海[span_2](end_span)
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

# 安装 Cloud Foundry CLI (根据架构自动选择)
RUN if [ "$TARGETARCH" = "amd64" ]; \
    then ARCH="x86-64"; else ARCH="arm64"; fi && \
    LATEST_TAG=$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    LATEST_VERSION=${LATEST_TAG#v} && \
    wget -O /tmp/cf.deb "https://github.com/cloudfoundry/cli/releases/download/${LATEST_TAG}/cf8-cli-installer_${LATEST_VERSION}_${ARCH}.deb" && \
    [span_3](start_span)dpkg -i /tmp/cf.deb && rm /tmp/cf.deb[span_3](end_span)

# 复制脚本并赋权
COPY keep_sap.sh /usr/local/bin/keep_sap.sh
RUN chmod +x /usr/local/bin/keep_sap.sh

# 设置 Cron 任务：必须以一个空行结尾，且使用 . [span_4](start_span)/etc/environment 加载变量[span_4](end_span)
RUN echo "30 8 * * * . /etc/environment; /bin/bash /usr/local/bin/keep_sap.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/sap-cron && \
    chmod 0644 /etc/cron.d/sap-cron && \
    echo "" >> /etc/cron.d/sap-cron

# 初始化日志文件
RUN touch /var/log/cron.log && chmod 666 /var/log/cron.log

# [span_5](start_span)启动命令：导出环境变量，启动 cron，实时查看日志[span_5](end_span)
CMD ["sh", "-c", "printenv > /etc/environment && cron && tail -f /var/log/cron.log"]
