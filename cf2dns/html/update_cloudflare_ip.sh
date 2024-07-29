#!/bin/bash

# 配置变量
API_TOKEN="your_api_token"
ZONE_ID="your_zone_id"
CM_RECORD_ID="your_cm_record_id"
CU_RECORD_ID="your_cu_record_id"
CT_RECORD_ID="your_ct_record_id"
BGP_RECORD_ID="your_bgp_record_id"
CM_RECORD_NAME="cm.your_domain.com"
CU_RECORD_NAME="cu.your_domain.com"
CT_RECORD_NAME="ct.your_domain.com"
BGP_RECORD_NAME="bgp.your_domain.com"

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

# 从 CSV 文件中提取峰值速度最快的 IP 地址
get_best_ip() {
  local FILE=$1
  local PREFIX=$2
  local IP=$(awk -F, -v prefix="$PREFIX" '
    $1 == prefix {
      gsub(/ MB| kB\/s| 毫秒/, "", $4); # 清理峰值速度和往返延迟字段中的单位
      speed[$2] = $4; # 使用 IP 地址作为键，峰值速度作为值
    }
    END {
      for (ip in speed) {
        if (max_speed < speed[ip]) {
          max_speed = speed[ip];
          best_ip = ip;
        }
      }
      print best_ip;
    }
  ' "$FILE")

  echo "$IP"
}

# 获取每个运营商的最佳 IP 地址
CM_IP=$(get_best_ip "CMCC_cdnspeedtestresult.csv" "CMCC")
CU_IP=$(get_best_ip "CU_cdnspeedtestresult.csv" "CU")
CT_IP=$(get_best_ip "CT_cdnspeedtestresult.csv" "CT")
BGP_IP=$(get_best_ip "BGP_cdnspeedtestresult.csv" "BGP")

# 更新 DNS 记录
if [[ -n "$CM_IP" ]]; then
  update_dns_record $CM_RECORD_ID $CM_RECORD_NAME $CM_IP
fi

if [[ -n "$CU_IP" ]]; then
  update_dns_record $CU_RECORD_ID $CU_RECORD_NAME $CU_IP
fi

if [[ -n "$CT_IP" ]]; then
  update_dns_record $CT_RECORD_ID $CT_RECORD_NAME $CT_IP
fi

if [[ -n "$BGP_IP" ]]; then
  update_dns_record $BGP_RECORD_ID $BGP_RECORD_NAME $BGP_IP
fi

echo "所有 DNS 记录已更新"
