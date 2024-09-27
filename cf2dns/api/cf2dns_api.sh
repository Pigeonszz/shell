#!/bin/bash

# 检查并安装依赖项
check_dependencies() {
  if ! command -v curl &> /dev/null; then
    echo "curl 未安装，正在安装..."
    if [ -f /etc/debian_version ]; then
      sudo apt-get update && sudo apt-get install -y curl
    elif [ -f /etc/centos-release ]; then
      sudo yum install -y curl
    elif [ -f /etc/arch-release ]; then
      sudo pacman -S --noconfirm curl
    elif [ -f /etc/alpine-release ]; then
      sudo apk add curl
    else
      echo "不支持的Linux发行版"
      exit 1
    fi
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq 未安装，正在安装..."
    if [ -f /etc/debian_version ]; then
      sudo apt-get update && sudo apt-get install -y jq
    elif [ -f /etc/centos-release ]; then
      sudo yum install -y epel-release
      sudo yum install -y jq
    elif [ -f /etc/arch-release ]; then
      sudo pacman -S --noconfirm jq
    elif [ -f /etc/alpine-release ]; then
      sudo apk add jq
    else
      echo "不支持的Linux发行版"
      exit 1
    fi
  fi
}

# 配置参数
API_URL="https://www.182682.xyz/api/cf2dns/get_cloudflare_ip"
KEY="o1zrmHAF"
CDN_SERVER=1
TYPE="v4"
CRITERIA="speed"  # "speed"(速度) "delay"(延迟) 二选一 

# 检查依赖项
check_dependencies

# 发送请求并获取数据
response=$(curl -s -G \
  --data-urlencode "key=$KEY" \
  --data-urlencode "cdn_server=$CDN_SERVER" \
  --data-urlencode "type=$TYPE" \
  "$API_URL")

# 检查请求是否成功
if [[ $(echo "$response" | jq -r '.status') == "true" ]]; then
  # 提取最佳IP地址信息
  best_ips=$(echo "$response" | jq -r --arg criteria "$CRITERIA" '.info | to_entries[] | .key as $operator | .value | sort_by(.[$criteria] | tonumber) | first | [$operator, .ip] | @csv')

  # 调试输出最佳IP地址信息
  echo "最佳IP地址信息: $best_ips"

  # 将最佳IP地址信息写入CSV文件
  echo "运营商,IP地址" > /usr/share/cdnmonitor.csv
  echo "$best_ips" >> /usr/share/cdnmonitor.csv

  echo "数据已成功保存到 /usr/share/cdnmonitor.csv"

  # 调用更新脚本
  /path/to/update_dns_from_csv.sh
else
  # 请求失败，输出错误信息
  error_msg=$(echo "$response" | jq -r '.msg')
  echo "请求失败: $error_msg"
  exit 1
fi
