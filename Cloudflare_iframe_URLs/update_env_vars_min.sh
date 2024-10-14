#!/bin/bash

TOKEN=""
ACCOUNT_ID=""
PROJECT_ID=""
IFRAME_URL=""

# 手动指定语言
LANGUAGE="EN"  # 设置为 "CN" 以使用中文

# 定义中英文的错误和成功消息
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

# 根据语言获取相应消息的函数
get_message() {
  local key=$1
  local lang=${2:-$LANGUAGE}
  echo "${key}_${lang}"
}

# LANGUAGE="CN"时设置镜像源的函数
set_mirror_source() {
  if [[ "$LANGUAGE" == "CN" ]]; then
    echo "正在设置镜像源为清华镜像..."
    
    if command -v sudo > /dev/null; then
      SUDO_CMD="sudo"
    else
      SUDO_CMD=""
    fi

    if command -v apt-get > /dev/null; then
      echo "设置 apt 镜像源..."
      $SUDO_CMD sed -i 's|http://archive.ubuntu.com/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list
      $SUDO_CMD sed -i 's|http://security.ubuntu.com/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list
      $SUDO_CMD apt-get update
    elif command -v yum > /dev/null; then
      echo "设置 yum 镜像源..."
      $SUDO_CMD sed -i.bak 's|^baseurl=.*|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/os/$basearch/|' /etc/yum.repos.d/CentOS-Base.repo
      $SUDO_CMD sed -i.bak 's|^mirrorlist=.*|#mirrorlist=|' /etc/yum.repos.d/CentOS-Base.repo
      $SUDO_CMD yum clean all
      $SUDO_CMD yum makecache
    elif command -v pacman > /dev/null; then
      echo "设置 pacman 镜像源..."
      $SUDO_CMD sed -i 's|^#Server = http://archlinux\.org/\$repo/os/\$arch|Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch|' /etc/pacman.d/mirrorlist
      $SUDO_CMD pacman -Sy
    elif command -v opkg > /dev/null; then
      echo "设置 opkg 镜像源..."
      echo "src/gz custom https://mirrors.tuna.tsinghua.edu.cn/openwrt/$(lsb_release -cs)/packages" | $SUDO_CMD tee -a /etc/opkg.conf
      $SUDO_CMD opkg update
    elif command -v apk > /dev/null; then
      echo "设置 apk 镜像源..."
      $SUDO_CMD sed -i 's|http://dl-cdn.alpinelinux.org/alpine/|https://mirrors.tuna.tsinghua.edu.cn/alpine/|g' /etc/apk/repositories
      $SUDO_CMD apk update
    else
      echo "$(get_message MSG_ERROR_UNSUPPORTED_PKG)"
      exit 1
    fi
  fi
}

# 检查依赖
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

# 更新配置函数
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

# 部署项目函数
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

# 执行依赖检查和镜像源设置
check_dependencies

set_mirror_source

update_config

sleep 5

deploy_project

echo "$(get_message MSG_DEPLOY_SUCCESS)"
