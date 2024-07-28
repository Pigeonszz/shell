#!/bin/bash

# 定义文件路径
speedtest_result_file="/usr/share/cloudflarespeedtestresult.txt"
log_file="/tmp/log/update_cloudflare_ip.log"

# 定义Cloudflare API相关信息
api_token=""
zone_id=""
record_id=""

# 确保日志文件夹存在
mkdir -p /tmp/log

# 获取当前时间
current_time=$(date '+%Y-%m-%d %H:%M:%S')

# 读取第一个IP地址（跳过第一行标题）
new_ip=$(awk -F',' 'NR==2 {print $1}' "$speedtest_result_file")

# 检查new_ip是否为空
if [ -z "$new_ip" ]; then
  echo "$current_time - 未能读取到有效的IP地址" >> "$log_file"
  exit 1
fi

# 更新Cloudflare DNS记录
response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
     -H "Authorization: Bearer $api_token" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"A\",\"name\":\"example.com\",\"content\":\"$new_ip\",\"proxied\":false}")

# 检查Cloudflare API请求是否成功
if echo "$response" | grep -q '"success":true'; then
  echo "$current_time - Cloudflare DNS记录已成功更新为: $new_ip" >> "$log_file"
else
  echo "$current_time - Cloudflare DNS记录更新失败: $response" >> "$log_file"
fi