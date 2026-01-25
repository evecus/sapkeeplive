#!/bin/bash

# 1. 强制加载 Docker 传入的环境变量
. /etc/environment

# 2. 验证变量
if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
    echo "$(date): 错误 - 未通过环境变量设置 EMAIL 或 PASSWORD"
    exit 1
fi

REGIONS="us sg"

# ===== 简易输出函数 =====
green() { echo -e "\033[1;32m$1\033[0m"; }
yellow() { echo -e "\033[1;33m$1\033[0m"; }
red() { echo -e "\033[1;31m$1\033[0m"; }

# ===== 登录与重启逻辑 =====
# (保持你原有的 login_cf, auto_target, restart_all_apps 函数不变)
# ... 

main() {
    # 注意：不再需要 install_cf_cli，因为 Dockerfile 已预装
    for region in $REGIONS; do
        login_cf "$region" || continue
        auto_target || continue
        restart_all_apps
    done
}

main
