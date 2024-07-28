#!/bin/bash

# 配置变量
API_TOKEN="your_api_token"
ZONE_ID="your_zone_id"
CM_RECORD_ID="your_cm_record_id"
CU_RECORD_ID="your_cu_record_id"
CT_RECORD_ID="your_ct_record_id"
CM_RECORD_NAME="cm.your_domain.com"
CU_RECORD_NAME="cu.your_domain.com"
CT_RECORD_NAME="ct.your_domain.com"

# 函数：更新 DNS 记录
update_dns_record() {
  local RECORD_ID=$1
  local RECORD_NAME=$2
  local NEW_IP=$3

  curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{
      "type": "A",
      "name": "'"$RECORD_NAME"'",
      "content": "'"$NEW_IP"'",
      "ttl": 1,
      "proxied": false
    }'
}

# 从 CSV 文件中读取 IP 地址并更新 DNS 记录
while IFS=, read -r operator ip; do
  operator=$(echo "$operator" | tr -d '"')
  ip=$(echo "$ip" | tr -d '"')

  case $operator in
    "CM")
      update_dns_record $CM_RECORD_ID $CM_RECORD_NAME $ip
      ;;
    "CU")
      update_dns_record $CU_RECORD_ID $CU_RECORD_NAME $ip
      ;;
    "CT")
      update_dns_record $CT_RECORD_ID $CT_RECORD_NAME $ip
      ;;
    *)
      echo "未知的运营商: $operator"
      ;;
  esac
done < <(tail -n +2 /usr/share/cdnmonitor.csv) # 跳过 CSV 标题行

echo "所有 DNS 记录已更新"
