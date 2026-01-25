#!/bin/bash

# 颜色定义
green() { echo -e "\e[1;32m$1\033[0m"; }
red() { echo -e "\e[1;91m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }

# 自动获取组织和空间
get_target_info() {
    ORG=$(cf orgs | sed -n '4p')
    SPACE=$(cf spaces | sed -n '4p')
    
    if [ -z "$ORG" ] || [ -z "$SPACE" ]; then
        red "未找到组织或空间信息"
        return 1
    fi
    cf target -o "$ORG" -s "$SPACE"
}

# 执行重启逻辑
restart_all_apps() {
    local region=$1
    local api=$2

    yellow "------------------------------------"
    green "开始处理区域: $region"
    
    # 登录
    cf login -a "$api" -u "$EMAIL" -p "$PASSWORD" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        red "$region 登录失败，请检查账号密码"
        return
    fi

    # 切换目标
    get_target_info
    
    # 获取应用并重启
    APPS=$(cf apps | awk 'NR>3 {print $1}' | grep -v '^$')
    if [ -z "$APPS" ]; then
        yellow "$region 区域未发现运行中的应用"
    else
        for APP in $APPS; do
            green "正在重启 [$region]: $APP"
            cf restart "$APP"
            sleep 5
        done
    fi
    
    # 退出登录防止干扰
    cf logout
}

# 主程序
echo "任务启动时间: $(date)"

# 重启 US 区域
restart_all_apps "US" "https://api.cf.us10-001.hana.ondemand.com"

# 重启 SG 区域
restart_all_apps "SG" "https://api.cf.ap21.hana.ondemand.com"

green "所有区域处理完毕"
