FROM --platform=$TARGETPLATFORM ubuntu:latest

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl wget ca-certificates tzdata cron \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

RUN if [ "$TARGETARCH" = "amd64" ]; then ARCH="x86-64"; else ARCH="arm64"; fi && \
    LATEST_TAG=$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    LATEST_VERSION=${LATEST_TAG#v} && \
    wget -O /tmp/cf.deb "https://github.com/cloudfoundry/cli/releases/download/${LATEST_TAG}/cf8-cli-installer_${LATEST_VERSION}_${ARCH}.deb" && \
    dpkg -i /tmp/cf.deb && rm /tmp/cf.deb

COPY keep_sap.sh /usr/local/bin/keep_sap.sh
RUN chmod +x /usr/local/bin/keep_sap.sh

# 每天 8:30 执行
RUN echo "30 8 * * * . /etc/environment; /bin/bash /usr/local/bin/keep_sap.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/sap-cron && \
    chmod 0644 /etc/cron.d/sap-cron

# 确保文件存在且可写
RUN touch /var/log/cron.log && chmod 666 /var/log/cron.log

# 这里的逻辑：先 touch 确保 tail 不会报错，再运行 cron
CMD ["sh", "-c", "touch /var/log/cron.log && printenv | grep -E 'CF_|URLS' > /etc/environment && cron && tail -f /var/log/cron.log"]
