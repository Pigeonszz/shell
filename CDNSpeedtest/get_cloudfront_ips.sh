#!/bin/bash

# 检查并安装依赖项
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo "错误：cURL 未安装。请使用以下命令安装："
        install_package curl
    fi

    if ! command -v jq &> /dev/null; then
        echo "错误：jq 未安装。请使用以下命令安装："
        install_package jq
    fi
}

# 安装包的函数
install_package() {
    local package=$1
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y $package
    elif command -v yum &> /dev/null; then
        sudo yum install -y $package
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y $package
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm $package
    elif command -v apk &> /dev/null; then
        sudo apk add $package
    else
        echo "错误：不支持的包管理器。请手动安装 cURL 和 jq。"
        exit 1
    fi
}

# 检查依赖项
check_dependencies

# 获取JSON数据
json_data=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json)

# 使用jq工具解析JSON数据，提取"service": "CLOUDFRONT"的项的IP，并排除CN IP
cloudfront_ips=$(echo "$json_data" | jq -r '.prefixes[] | select(.service == "CLOUDFRONT" and .region != "cn-north-1" and .region != "cn-northwest-1") | .ip_prefix')

# 将纯文本IP CIDR格式输出到cft_ip.txt文件
echo "$cloudfront_ips" > cft_ip.txt

echo "IP CIDR 格式已保存到 cft_ip.txt 文件中。"