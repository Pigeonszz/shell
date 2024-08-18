#!/bin/bash

# 配置部分
API_URL="https://ipdb.api.030101.xyz/?type=bestproxy"
ZONE_ID="你的Cloudflare Zone ID"
API_TOKEN="你的Cloudflare API令牌"
DOMAIN_NAME="domain_name"

# 获取最新的ProxyIP列表
ProxyIPList=$(curl -s "$API_URL")

# 检查获取的IP列表是否有效
if [[ -z "$ProxyIPList" ]]; then
    echo "未能获取ProxyIP列表"
    exit 1
fi

echo "获取的ProxyIP列表: $ProxyIPList"

# 获取当前的DNS记录ID并删除旧记录
CURRENT_RECORDS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DOMAIN_NAME" \
     -H "Authorization: Bearer $API_TOKEN" \
     -H "Content-Type: application/json")

RECORD_IDS=$(echo "$CURRENT_RECORDS" | jq -r '.result[] | select(.type == "A") | .id')

if [[ -n "$RECORD_IDS" ]]; then
    for RECORD_ID in $RECORD_IDS; do
        echo "删除旧的DNS记录ID: $RECORD_ID"
        curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json"
    done
else
    echo "没有找到现有的A记录。"
fi

# 添加新的ProxyIP到DNS记录
IFS=$'\n'
for ProxyIP in $ProxyIPList; do
    # 检查IP是否有效
    if [[ "$ProxyIP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "添加新的DNS记录: $ProxyIP"
        RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
             -H "Authorization: Bearer $API_TOKEN" \
             -H "Content-Type: application/json" \
             --data "{\"type\":\"A\",\"name\":\"$DOMAIN_NAME\",\"content\":\"$ProxyIP\",\"ttl\":60\"proxied\":false}")

        if echo "$RESPONSE" | grep -q '"success":true'; then
            echo "DNS记录添加成功: $ProxyIP"
        else
            echo "DNS记录添加失败: $RESPONSE"
        fi
    else
        echo "无效的IP地址: $ProxyIP"
    fi
done
