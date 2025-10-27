#!/bin/sh

# IPv6 Tools - OpenClash Auto Control Script
# Copyright (C) 2025
# Licensed under GPL v3

. /lib/functions.sh
. /lib/functions/network.sh

LOG_TAG="ipv6-tools"
LOCK_FILE="/var/run/ipv6-tools.lock"
STATUS_CACHE="/tmp/ipv6-tools-status"

# 获取UCI配置
config_load "ipv6-tools"

get_config() {
    local section=$1
    local option=$2
    local default=$3
    uci -q get ipv6-tools.$section.$option 2>/dev/null || echo "$default"
}

# 日志函数
log_msg() {
    local level=$1
    shift
    local message="$@"
    local log_enabled=$(get_config "log" "enable" "1")

    if [ "$log_enabled" = "1" ]; then
        logger -t "$LOG_TAG" -p "daemon.$level" "$message"

        local log_file=$(get_config "log" "log_file" "/var/log/ipv6-tools.log")
        echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$log_file"
    fi
}

# 检查OpenClash状态
check_openclash_status() {
    local status_cmd=$(get_config "openclash" "status_command" "/etc/init.d/openclash status")

    if $status_cmd >/dev/null 2>&1; then
        echo "running"
    else
        echo "stopped"
    fi
}

# 启动OpenClash
start_openclash() {
    local start_cmd=$(get_config "openclash" "start_command" "/etc/init.d/openclash restart")

    log_msg "info" "Starting OpenClash..."
    if $start_cmd >/dev/null 2>&1; then
        log_msg "info" "OpenClash started successfully"
        echo "running" > "$STATUS_CACHE"
        return 0
    else
        log_msg "error" "Failed to start OpenClash"
        return 1
    fi
}

# 停止OpenClash
stop_openclash() {
    local stop_cmd=$(get_config "openclash" "stop_command" "/etc/init.d/openclash stop")

    log_msg "info" "Stopping OpenClash..."
    if $stop_cmd >/dev/null 2>&1; then
        log_msg "info" "OpenClash stopped successfully"
        echo "stopped" > "$STATUS_CACHE"
        return 0
    else
        log_msg "error" "Failed to stop OpenClash"
        return 1
    fi
}

# 检查域名是否需要VPN
check_domain_vpn_need() {
    local domain=$1
    local domain_list=$(get_config "openclash" "domain_list" "")

    if [ -z "$domain_list" ]; then
        return 1
    fi

    echo "$domain_list" | tr ',' '\n' | while read -r pattern; do
        if [ -n "$pattern" ]; then
            case "$domain" in
                *$pattern*) return 0 ;;
            esac
        fi
    done

    return 1
}

# 检查IP是否需要VPN
check_ip_vpn_need() {
    local ip=$1
    local ip_list=$(get_config "openclash" "ip_list" "")

    if [ -z "$ip_list" ]; then
        return 1
    fi

    echo "$ip_list" | tr ',' '\n' | while read -r ip_pattern; do
        if [ -n "$ip_pattern" ]; then
            case "$ip" in
                $ip_pattern*) return 0 ;;
            esac
        fi
    done

    return 1
}

# 监控网络连接
monitor_connections() {
    local check_interval=$(get_config "traffic" "check_interval" "10")
    local idle_timeout=$(get_config "global" "idle_timeout" "300")
    local last_activity=$(cat "/tmp/ipv6-tools-last-activity" 2>/dev/null || echo "$(date +%s)")
    local current_time=$(date +%s)

    # 检查是否有需要VPN的连接
    local vpn_needed=0

    # 检查DNS解析
    if [ -f "/tmp/dnsmasq.log" ]; then
        tail -n 100 /tmp/dnsmasq.log | grep -i "query\|forward" | while read line; do
            domain=$(echo "$line" | grep -oE 'query[[:space:]]+\[^[:space:]]+' | cut -d' ' -f2)
            if [ -n "$domain" ] && check_domain_vpn_need "$domain"; then
                vpn_needed=1
                break
            fi
        done
    fi

    # 检查当前连接
    if [ -f "/proc/net/tcp" ] || [ -f "/proc/net/tcp6" ]; then
        cat /proc/net/tcp /proc/net/tcp6 2>/dev/null | while read line; do
            local_ip=$(echo "$line" | awk '{print $2}' | cut -d':' -f1)
            remote_ip=$(echo "$line" | awk '{print $3}' | cut -d':' -f1)

            # 转换IP格式
            if [ -n "$remote_ip" ]; then
                hex_ip=$(echo "$remote_ip" | tr '[:upper:]' '[:lower:]')
                # 简化的十六进制IP转十进制IP
                dec_ip=$(printf "%d.%d.%d.%d" 0x${hex_ip:6:2} 0x${hex_ip:4:2} 0x${hex_ip:2:2} 0x${hex_ip:0:2})

                if check_ip_vpn_need "$dec_ip"; then
                    vpn_needed=1
                    break
                fi
            fi
        done
    fi

    # 检查流量统计
    local interface=$(get_config "traffic" "interface" "all")
    local min_traffic_kb=$(get_config "traffic" "min_traffic_kb" "10")

    if [ "$interface" != "all" ]; then
        local rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
        local tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
        local total_bytes=$((rx_bytes + tx_bytes))
        local total_kb=$((total_bytes / 1024))

        if [ "$total_kb" -gt "$min_traffic_kb" ]; then
            vpn_needed=1
        fi
    fi

    echo "$current_time" > "/tmp/ipv6-tools-last-activity"

    return $vpn_needed
}

# 主控制逻辑
main_control() {
    # 检查锁文件，防止重复运行
    [ -f "$LOCK_FILE" ] && return
    touch "$LOCK_FILE"

    local global_enabled=$(get_config "global" "enable" "0")
    local auto_control_enabled=$(get_config "openclash" "enable" "1")

    if [ "$global_enabled" != "1" ] || [ "$auto_control_enabled" != "1" ]; then
        rm -f "$LOCK_FILE"
        return
    fi

    local current_status=$(check_openclash_status)
    local idle_timeout=$(get_config "global" "idle_timeout" "300")
    local current_time=$(date +%s)
    local last_activity=$(cat "/tmp/ipv6-tools-last-activity" 2>/dev/null || echo "$current_time")
    local idle_time=$((current_time - last_activity))

    if monitor_connections; then
        # 需要VPN，确保OpenClash运行
        log_msg "debug" "VPN access detected, ensuring OpenClash is running"
        if [ "$current_status" = "stopped" ]; then
            start_openclash
        fi
        echo "$current_time" > "/tmp/ipv6-tools-last-activity"
    else
        # 不需要VPN，检查是否超时
        if [ "$current_status" = "running" ] && [ "$idle_time" -gt "$idle_timeout" ]; then
            log_msg "info" "No VPN activity for ${idle_time}s, stopping OpenClash"
            stop_openclash
        fi
    fi

    rm -f "$LOCK_FILE"
}

# 初始化
init() {
    local startup_delay=$(get_config "global" "startup_delay" "10")
    log_msg "info" "IPv6 Tools starting up (delay: ${startup_delay}s)"
    sleep "$startup_delay"

    # 创建状态缓存目录
    mkdir -p "$(dirname "$STATUS_CACHE")"
    mkdir -p "$(dirname "/tmp/ipv6-tools-last-activity")"

    # 初始化状态
    check_openclash_status > "$STATUS_CACHE"
}

case "$1" in
    start)
        init
        ;;
    stop)
        log_msg "info" "IPv6 Tools stopping"
        rm -f "$LOCK_FILE"
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    status)
        check_openclash_status
        ;;
    monitor)
        main_control
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|monitor}"
        exit 1
        ;;
esac