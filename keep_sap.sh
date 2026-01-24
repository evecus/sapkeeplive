#!/bin/bash

# 从环境变量读取，如果为空则报错退出
EMAIL="${CF_EMAIL}"
PASSWORD="${CF_PASSWORD}"
URLS="${CF_URLS}"

if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
    echo "$(date): 错误 - 未设置 CF_EMAIL 或 CF_PASSWORD 环境变量"
    exit 1
fi

# 颜色定义
green() { echo -e "\e[1;32m$1\033[0m"; }
red() { echo -e "\e[1;91m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }

# 登录并重启逻辑 (已保留你原始的核心逻辑)
login_cf() {
    local region="$1"
    local api_endpoint=""
    case "$region" in
        "us") api_endpoint="https://api.cf.us10-001.hana.ondemand.com" ;;
        "sg") api_endpoint="https://api.cf.ap21.hana.ondemand.com" ;;
        *) red "未知区域: $region"; return 1 ;;
    esac
    
    green "尝试登录到 $region 区域..."
    cf login -a "$api_endpoint" -u "$EMAIL" -p "$PASSWORD" -o "$ORG" -s "$SPACE" > /dev/null 2>&1
    
    # 自动获取组织和空间的简易逻辑
    ORG=$(cf orgs | sed -n '4p')
    SPACE=$(cf spaces | sed -n '4p')
    cf target -o "$ORG" -s "$SPACE"
}

restart_apps() {
    APP_NAMES=$(cf apps | awk 'NR>3 {print $1}' | grep -v '^$')
    for APP_NAME in $APP_NAMES; do
        yellow "正在重启应用: $APP_NAME"
        cf restart "$APP_NAME"
        sleep 15
    done
}

monitor_urls() {
    for URL in $URLS; do
        yellow "检查 URL: $URL"
        STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 10 "$URL")
        if [ "$STATUS_CODE" -ne 200 ]; then
            if echo "$URL" | grep -q "us10-001"; then
                login_cf "us" && restart_apps
            elif echo "$URL" | grep -q "ap21"; then
                login_cf "sg" && restart_apps
            fi
        else
            green "状态正常: $STATUS_CODE"
        fi
    done
}

# 容器内直接执行监控
monitor_urls
