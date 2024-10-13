#!/bin/bash

TOKEN=""
ACCOUNT_ID=""
PROJECT_ID=""
IFRAME_URL=""

# Manually specify the language
LANGUAGE="EN"  # Set this to "CN" for Chinese

# Define messages in both Chinese and English
MSG_ERROR_DEPENDENCY_CN="错误：cURL 未安装。请使用以下命令安装："
MSG_ERROR_DEPENDENCY_EN="Error: cURL is not installed. Please install it using the following command:"
MSG_ERROR_UNSUPPORTED_PKG_CN="错误：不支持的包管理器。请手动安装 cURL。"
MSG_ERROR_UNSUPPORTED_PKG_EN="Error: Unsupported package manager. Please install cURL manually."
MSG_ERROR_CONFIG_CN="错误：配置更新失败（HTTP 状态码："
MSG_ERROR_CONFIG_EN="Error: Configuration update failed (HTTP status code:"
MSG_ERROR_DEPLOY_CN="错误：项目部署失败（HTTP 状态码："
MSG_ERROR_DEPLOY_EN="Error: Project deployment failed (HTTP status code:"
MSG_DEPLOY_SUCCESS_CN="部署已成功触发。"
MSG_DEPLOY_SUCCESS_EN="Deployment has been successfully triggered."

# Function to get the appropriate message based on the language
get_message() {
  local key=$1
  local lang=${2:-$LANGUAGE}
  echo "${key}_${lang}"
}

check_dependencies() {
  if command -v apt-get > /dev/null; then
    if ! dpkg -s curl > /dev/null 2>&1; then
      if command -v sudo > /dev/null; then
        echo "$(get_message MSG_ERROR_DEPENDENCY) sudo apt-get install curl"
      else
        echo "$(get_message MSG_ERROR_DEPENDENCY) apt-get install curl"
      fi
      exit 1
    fi
  elif command -v yum > /dev/null; then
    if ! rpm -q curl > /dev/null 2>&1; then
      if command -v sudo > /dev/null; then
        echo "$(get_message MSG_ERROR_DEPENDENCY) sudo yum install curl"
      else
        echo "$(get_message MSG_ERROR_DEPENDENCY) yum install curl"
      fi
      exit 1
    fi
  elif command -v pacman > /dev/null; then
    if ! pacman -Qi curl > /dev/null 2>&1; then
      if command -v sudo > /dev/null; then
        echo "$(get_message MSG_ERROR_DEPENDENCY) sudo pacman -S curl"
      else
        echo "$(get_message MSG_ERROR_DEPENDENCY) pacman -S curl"
      fi
      exit 1
    fi
  elif command -v opkg > /dev/null; then
    if ! opkg list-installed | grep -q curl; then
      if command -v sudo > /dev/null; then
        echo "$(get_message MSG_ERROR_DEPENDENCY) sudo opkg update && sudo opkg install curl"
      else
        echo "$(get_message MSG_ERROR_DEPENDENCY) opkg update && opkg install curl"
      fi
      exit 1
    fi
  elif command -v apk > /dev/null; then
    if ! apk info | grep -q curl; then
      if command -v sudo > /dev/null; then
        echo "$(get_message MSG_ERROR_DEPENDENCY) sudo apk add curl"
      else
        echo "$(get_message MSG_ERROR_DEPENDENCY) apk add curl"
      fi
      exit 1
    fi
  else
    echo "$(get_message MSG_ERROR_UNSUPPORTED_PKG)"
    exit 1
  fi
}

update_config() {
  response=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
    \"deployment_configs\": {
      \"production\": {
        \"env_vars\": {
          \"IFRAME_URL\": {
            \"type\": \"plain_text\",
            \"value\": \"$IFRAME_URL\"
          }
        }
      }
    }
  }" \
    "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/$PROJECT_ID")

  if [[ "$response" -ne 200 ]]; then
    echo "$(get_message MSG_ERROR_CONFIG) $response)"
    exit 1
  fi
}

deploy_project() {
  response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/$PROJECT_ID/deployments")

  if [[ "$response" -ne 200 ]]; then
    echo "$(get_message MSG_ERROR_DEPLOY) $response)"
    exit 1
  fi
}

check_dependencies

update_config

sleep 5

deploy_project

echo "$(get_message MSG_DEPLOY_SUCCESS)"