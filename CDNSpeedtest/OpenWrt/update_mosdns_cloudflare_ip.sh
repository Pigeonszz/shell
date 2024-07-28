#!/bin/bash

# 定义文件路径
speedtest_result_file="/usr/share/cloudflarespeedtestresult.txt"
config_file="/etc/config/mosdns"
log_file="/tmp/log/update_cloudflare_ip.log"

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

# 使用sed命令替换list cloudflare_ip的值
sed -i "s/list cloudflare_ip .*/list cloudflare_ip '$new_ip'/g" "$config_file"

# 重启MosDNS服务使更改生效
/etc/init.d/mosdns restart

# 记录日志
echo "$current_time - Cloudflare IP地址已更新为: $new_ip" >> "$log_file"