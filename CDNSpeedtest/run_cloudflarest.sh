#!/bin/bash

# 定义默认参数
THREADS=200          # 延迟测速线程数
TRIES=10              # 延迟测速次数
DOWNLOAD_NUM=10      # 下载测速数量
DOWNLOAD_TIME=10     # 下载测速时间
PORT=443             # 指定测速端口
URL="https://cf.xiu2.xyz/url"  # 指定测速地址
HTTPING=false        # 是否切换到HTTPing测速模式
HTTPING_CODE=200     # HTTPing测速时的有效状态码
CFCOLO="HKG,KHH,NRT,LAX,SEA,SJC,FRA,MAD"  # 匹配指定地区
DELAY_UPPER=500      # 平均延迟上限
DELAY_LOWER=40       # 平均延迟下限
LOSS_RATE=0.2        # 丢包几率上限
SPEED_LOWER=5        # 下载速度下限
RESULT_NUM=10        # 显示结果数量
IP_FILE="ip.txt"     # IP段数据文件
IP_RANGE=""          # 指定IP段数据
OUTPUT_FILE="result.csv"  # 写入结果文件
DISABLE_DOWNLOAD=false  # 是否禁用下载测速
ALL_IP=false         # 是否测速全部IP

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n) THREADS="$2"; shift ;;  # 设置延迟测速线程数
        -t) TRIES="$2"; shift ;;    # 设置延迟测速次数
        -dn) DOWNLOAD_NUM="$2"; shift ;;  # 设置下载测速数量
        -dt) DOWNLOAD_TIME="$2"; shift ;;  # 设置下载测速时间
        -tp) PORT="$2"; shift ;;    # 设置测速端口
        -url) URL="$2"; shift ;;    # 设置测速地址
        -httping) HTTPING=true ;;   # 切换到HTTPing测速模式
        -httping-code) HTTPING_CODE="$2"; shift ;;  # 设置HTTPing测速时的有效状态码
        -cfcolo) CFCOLO="$2"; shift ;;  # 设置匹配指定地区
        -tl) DELAY_UPPER="$2"; shift ;;  # 设置平均延迟上限
        -tll) DELAY_LOWER="$2"; shift ;;  # 设置平均延迟下限
        -tlr) LOSS_RATE="$2"; shift ;;   # 设置丢包几率上限
        -sl) SPEED_LOWER="$2"; shift ;;  # 设置下载速度下限
        -p) RESULT_NUM="$2"; shift ;;    # 设置显示结果数量
        -f) IP_FILE="$2"; shift ;;       # 设置IP段数据文件
        -ip) IP_RANGE="$2"; shift ;;     # 设置指定IP段数据
        -o) OUTPUT_FILE="$2"; shift ;;   # 设置写入结果文件
        -dd) DISABLE_DOWNLOAD=true ;;    # 禁用下载测速
        -allip) ALL_IP=true ;;           # 测速全部IP
        -v) echo "CloudflareST Version: $(./CloudflareST -v)"; exit 0 ;;  # 打印程序版本并检查更新
        -h) ./CloudflareST -h; exit 0 ;;   # 打印帮助说明
        *) echo "未知参数: $1"; exit 1 ;;  # 未知参数处理
    esac
    shift
done

# 构建命令
COMMAND="./CloudflareST"
COMMAND+=" -n $THREADS"
COMMAND+=" -t $TRIES"
COMMAND+=" -dn $DOWNLOAD_NUM"
COMMAND+=" -dt $DOWNLOAD_TIME"
COMMAND+=" -tp $PORT"
COMMAND+=" -url $URL"
if $HTTPING; then
    COMMAND+=" -httping"
    COMMAND+=" -httping-code $HTTPING_CODE"
    COMMAND+=" -cfcolo $CFCOLO"
fi
COMMAND+=" -tl $DELAY_UPPER"
COMMAND+=" -tll $DELAY_LOWER"
COMMAND+=" -tlr $LOSS_RATE"
COMMAND+=" -sl $SPEED_LOWER"
COMMAND+=" -p $RESULT_NUM"
COMMAND+=" -f $IP_FILE"
if [ -n "$IP_RANGE" ]; then
    COMMAND+=" -ip $IP_RANGE"
fi
COMMAND+=" -o $OUTPUT_FILE"
if $DISABLE_DOWNLOAD; then
    COMMAND+=" -dd"
fi
if $ALL_IP; then
    COMMAND+=" -allip"
fi

# 执行命令
echo "执行命令: $COMMAND"
eval $COMMAND