#!/bin/bash

# 从环境变量读取，如果为空则报错退出
EMAIL="${EMAIL}"
PASSWORD="${PASSWORD}"

if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
    echo "$(date): 错误 - 未设置 EMAIL 或 PASSWORD 环境变量"
    exit 1
fi

REGIONS="us sg"

# ===== 颜色 =====
green() { echo -e "\033[1;32m$1\033[0m"; }
yellow() { echo -e "\033[1;33m$1\033[0m"; }
red() { echo -e "\033[1;31m$1\033[0m"; }

# ===== 安装 CF CLI（如果没有）=====
install_cf_cli() {
    if command -v cf >/dev/null 2>&1; then
        green "CF CLI 已存在"
        return
    fi

    yellow "安装 CF CLI..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64) ARCH_TYPE="x86-64" ;;
        aarch64|arm64) ARCH_TYPE="arm64" ;;
        *) red "不支持架构 $ARCH"; exit 1 ;;
    esac

    TAG=$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases/latest \
        | grep tag_name | cut -d '"' -f 4)
    VER=${TAG#v}
    PKG="cf8-cli-installer_${VER}_${ARCH_TYPE}.deb"
    URL="https://github.com/cloudfoundry/cli/releases/download/${TAG}/${PKG}"

    wget -O /tmp/cf.deb "$URL" && dpkg -i /tmp/cf.deb || apt -f install -y
}

# ===== 登录 CF =====
login_cf() {
    REGION="$1"
    case "$REGION" in
        us) API="https://api.cf.us10-001.hana.ondemand.com" ;;
        sg) API="https://api.cf.ap21.hana.ondemand.com" ;;
        *) red "未知区域 $REGION"; return 1 ;;
    esac

    green "登录区域: $REGION"
    cf login -a "$API" -u "$EMAIL" -p "$PASSWORD" --skip-ssl-validation || return 1
}

# ===== 自动获取 org / space =====
auto_target() {
    ORG=$(cf orgs | awk 'NR==4 {print $1}')
    SPACE=$(cf spaces | awk 'NR==4 {print $1}')

    if [ -z "$ORG" ] || [ -z "$SPACE" ]; then
        red "无法获取 org 或 space"
        return 1
    fi

    cf target -o "$ORG" -s "$SPACE"
    green "使用组织: $ORG / 空间: $SPACE"
}

# ===== 重启所有应用 =====
restart_all_apps() {
    APPS=$(cf apps | awk 'NR>3 {print $1}')

    if [ -z "$APPS" ]; then
        yellow "该空间没有应用"
        return
    fi

    for app in $APPS; do
        yellow "重启应用: $app"
        cf restart "$app"
        sleep 10
    done
}

# ===== 主流程 =====
main() {
    install_cf_cli

    for region in $REGIONS; do
        login_cf "$region" || continue
        auto_target || continue
        restart_all_apps
    done
}

main
