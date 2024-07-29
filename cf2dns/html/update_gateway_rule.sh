#!/bin/bash

# 变量设置
account_id="your_account_id"         # Cloudflare账户ID
rule_id="your_rule_id"               # 要更新的规则ID
api_token="your_api_token"           # Cloudflare API令牌
csv_file="BGP_cdnspeedtestresult.csv" # CSV文件路径
api_url="https://api.cloudflare.com/client/v4/accounts/${account_id}/gateway/rules/${rule_id}"

# 临时文件
temp_file=$(mktemp)

# 从CSV文件中提取IP地址列表并按 speed 和 delay 排序
awk -F, 'NR > 1 {print $2","$4","$5}' "$csv_file" | sort -t, -k2,2nr -k3,3n > "$temp_file"

# 读取排序后的文件中最优的IP地址（假设IP在第一行）
best_ip=$(head -n 1 "$temp_file" | cut -d, -f1)

# 获取当前规则的详细信息
current_rule=$(curl -s -X GET "$api_url" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json")

# 更新规则的JSON负载（仅更新override_ips字段）
update_payload=$(echo "$current_rule" | jq --arg ip "$best_ip" \
    '.result.rule_settings.override_ips = [$ip] | .result |= (. + {rule_settings: .result.rule_settings})' | jq '{rule_settings: .result.rule_settings}')

# 发送PUT请求更新Cloudflare规则
response=$(curl -s -X PUT "$api_url" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json" \
    -d "$update_payload")

# 输出响应
echo "规则更新响应："
echo "$response"

# 清理临时文件
rm "$temp_file"
