#!/bin/sh

# 请求URL并获取HTML内容
url="https://www.182682.xyz/page/cloudflare/ipv4.html"
html_content=$(curl -s $url)

# 使用awk解析HTML并生成CSV文件
echo "$html_content" | awk '
    BEGIN {
        RS = "</tr>"; FS = "<td>|</td>"
        OFS = ","
    }
    {
        if (NF > 1) {
            line_name = $2
            preferred_address = $4
            bandwidth = $6
            peak_speed = $8
            rtt = $10
            data_center = $12
            update_time = $14
            gsub(/^[ \t]+|[ \t]+$/, "", line_name)  # 去掉行名称的前后空格

            # 替换线路名称
            if (line_name == "电信") {
                line_name = "CT"
            } else if (line_name == "联通") {
                line_name = "CU"
            } else if (line_name == "移动") {
                line_name = "CMCC"
            } else if (line_name == "国内") {
                line_name = "BGP"
            }

            if (line_name != "") {
                filename = line_name "_cdnspeedtestresult.csv"
                if (!(filename in seen)) {
                    print "线路名称,优选地址,网络带宽,峰值速度,往返延迟,数据中心,更新时间" > filename
                    seen[filename]
                }
                print line_name, preferred_address, bandwidth, peak_speed, rtt, data_center, update_time >> filename
            }
        }
    }
' | sed -e 's/<[^>]*>//g' -e 's/^[ \t]*//;s/[ \t]*$//'

  # 调用更新脚本
#  /path/to/update_01.sh
#  /path/to/update_02.sh
#  /path/to/update_03.sh