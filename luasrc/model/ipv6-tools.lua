-- IPv6 Tools LuCI Model
-- Copyright (C) 2025
-- Licensed under GPL v3

local nixio = require "nixio"
local sys = require "luci.sys"
local util = require "luci.util"
local uci = require "luci.model.uci".cursor()

module "luci.model.ipv6-tools"

local M = {}

-- 配置获取函数
function M.get_config(section, option, default)
    local value = uci:get("ipv6-tools", section, option)
    return value or default
end

-- 配置设置函数
function M.set_config(section, option, value)
    return uci:set("ipv6-tools", section, option, value)
end

-- 提交配置更改
function M.commit_config()
    return uci:commit("ipv6-tools")
end

-- 检查服务状态
function M.get_service_status()
    local status_file = "/tmp/ipv6-tools-status"
    local f = io.open(status_file, "r")
    if f then
        local status = f:read("*a"):gsub("%s+", "")
        f:close()
        return status
    end

    -- 如果状态文件不存在，尝试检查OpenClash状态
    local handle = io.popen("/etc/init.d/openclash status 2>/dev/null && echo 'running' || echo 'stopped'")
    if handle then
        local status = handle:read("*a"):gsub("%s+", "")
        handle:close()
        return status
    end

    return "unknown"
end

-- 启动OpenClash
function M.start_openclash()
    local start_cmd = M.get_config("openclash", "start_command", "/etc/init.d/openclash restart")
    local result = sys.call(start_cmd .. " >/dev/null 2>&1")

    -- 更新状态缓存
    local status_file = io.open("/tmp/ipv6-tools-status", "w")
    if status_file then
        status_file:write("running")
        status_file:close()
    end

    return result == 0
end

-- 停止OpenClash
function M.stop_openclash()
    local stop_cmd = M.get_config("openclash", "stop_command", "/etc/init.d/openclash stop")
    local result = sys.call(stop_cmd .. " >/dev/null 2>&1")

    -- 更新状态缓存
    local status_file = io.open("/tmp/ipv6-tools-status", "w")
    if status_file then
        status_file:write("stopped")
        status_file:close()
    end

    return result == 0
end

-- 获取网络连接信息
function M.get_network_connections()
    local connections = {}

    -- 获取TCP连接
    local tcp_handle = io.popen("cat /proc/net/tcp /proc/net/tcp6 2>/dev/null")
    if tcp_handle then
        for line in tcp_handle:lines() do
            if string.match(line, "^%s*%d+") then
                local parts = {}
                for part in string.gmatch(line, "%S+") do
                    table.insert(parts, part)
                end

                if #parts >= 4 then
                    local local_addr = M.parse_ip_address(parts[2])
                    local remote_addr = M.parse_ip_address(parts[3])
                    local state = M.get_tcp_state(tonumber(parts[4], 16))

                    table.insert(connections, {
                        local_addr = local_addr,
                        remote_addr = remote_addr,
                        state = state,
                        protocol = "TCP"
                    })
                end
            end
        end
        tcp_handle:close()
    end

    return connections
end

-- 解析IP地址
function M.parse_ip_address(hex_addr)
    if not hex_addr or hex_addr == "" then
        return "N/A"
    end

    -- 移除端口号
    local ip_hex = string.match(hex_addr, "^(%x+):")
    if not ip_hex then
        return hex_addr
    end

    -- IPv4地址解析
    if string.len(ip_hex) == 8 then
        local p1 = tonumber(string.sub(ip_hex, 7, 8), 16)
        local p2 = tonumber(string.sub(ip_hex, 5, 6), 16)
        local p3 = tonumber(string.sub(ip_hex, 3, 4), 16)
        local p4 = tonumber(string.sub(ip_hex, 1, 2), 16)
        return string.format("%d.%d.%d.%d", p1, p2, p3, p4)
    end

    -- IPv6地址简化显示
    return string.sub(ip_hex, 1, 16) .. "..."
end

-- 获取TCP状态
function M.get_tcp_state(state_code)
    local states = {
        [0x01] = "ESTABLISHED",
        [0x02] = "SYN_SENT",
        [0x03] = "SYN_RECV",
        [0x04] = "FIN_WAIT1",
        [0x05] = "FIN_WAIT2",
        [0x06] = "TIME_WAIT",
        [0x07] = "CLOSE",
        [0x08] = "CLOSE_WAIT",
        [0x09] = "LAST_ACK",
        [0x0A] = "LISTEN",
        [0x0B] = "CLOSING"
    }

    return states[state_code] or "UNKNOWN"
end

-- 检查是否为VPN域名
function M.is_vpn_domain(domain)
    local domain_list = M.get_config("openclash", "domain_list", "")
    if not domain_list or domain_list == "" then
        return false
    end

    for pattern in string.gmatch(domain_list, "[^,]+") do
        pattern = pattern:gsub("%s+", "")
        if pattern ~= "" and string.match(domain, pattern) then
            return true
        end
    end

    return false
end

-- 获取流量统计
function M.get_traffic_stats(interface)
    interface = interface or "all"
    local stats = {}

    if interface == "all" then
        -- 获取所有接口的流量统计
        local handle = io.popen("cat /proc/net/dev | grep -E '^[a-zA-Z]' | awk '{print $1, $2, $10}'")
        if handle then
            for line in handle:lines() do
                local iface, rx_bytes, tx_bytes = string.match(line, "^(.-):%s+(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)")
                if iface then
                    iface = iface:gsub("%s+", "")
                    stats[iface] = {
                        rx_bytes = tonumber(rx_bytes) or 0,
                        tx_bytes = tonumber(tx_bytes) or 0
                    }
                end
            end
            handle:close()
        end
    else
        -- 获取指定接口的流量统计
        local rx_file = string.format("/sys/class/net/%s/statistics/rx_bytes", interface)
        local tx_file = string.format("/sys/class/net/%s/statistics/tx_bytes", interface)

        local rx_handle = io.open(rx_file, "r")
        local tx_handle = io.open(tx_file, "r")

        if rx_handle and tx_handle then
            local rx_bytes = rx_handle:read("*a"):gsub("%s+", "")
            local tx_bytes = tx_handle:read("*a"):gsub("%s+", "")

            stats[interface] = {
                rx_bytes = tonumber(rx_bytes) or 0,
                tx_bytes = tonumber(tx_bytes) or 0
            }

            rx_handle:close()
            tx_handle:close()
        end
    end

    return stats
end

-- 读取日志文件
function M.get_log_lines(lines)
    lines = lines or 50
    local log_file = M.get_config("log", "log_file", "/var/log/ipv6-tools.log")

    local handle = io.popen(string.format("tail -n %d '%s' 2>/dev/null || echo 'Log file not found'", lines, log_file))
    if handle then
        local content = handle:read("*a")
        handle:close()
        return content
    end

    return "Log file not found"
end

-- 验证配置
function M.validate_config()
    local errors = {}

    -- 检查基本配置
    local check_interval = M.get_config("global", "check_interval", "5")
    if not tonumber(check_interval) or tonumber(check_interval) < 1 then
        table.insert(errors, "检查间隔必须是大于0的数字")
    end

    local idle_timeout = M.get_config("global", "idle_timeout", "300")
    if not tonumber(idle_timeout) or tonumber(idle_timeout) < 60 then
        table.insert(errors, "空闲超时必须大于60秒")
    end

    -- 检查命令是否存在
    local start_cmd = M.get_config("openclash", "start_command", "/etc/init.d/openclash restart")
    local stop_cmd = M.get_config("openclash", "stop_command", "/etc/init.d/openclash stop")
    local status_cmd = M.get_config("openclash", "status_command", "/etc/init.d/openclash status")

    if not nixio.fs.access(start_cmd:match("^%S+")) then
        table.insert(errors, "启动命令不存在: " .. start_cmd:match("^%S+"))
    end

    if not nixio.fs.access(stop_cmd:match("^%S+")) then
        table.insert(errors, "停止命令不存在: " .. stop_cmd:match("^%S+"))
    end

    if not nixio.fs.access(status_cmd:match("^%S+")) then
        table.insert(errors, "状态检查命令不存在: " .. status_cmd:match("^%S+"))
    end

    return errors
end

return M