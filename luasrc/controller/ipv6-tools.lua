-- IPv6 Tools LuCI Controller
-- Copyright (C) 2025
-- Licensed under GPL v3

module("luci.controller.ipv6-tools", package.seeall)

function index()
    entry({"admin", "services", "ipv6-tools"}, cbi("ipv6-tools/general"), _("IPv6 Tools"), 60)
    entry({"admin", "services", "ipv6-tools", "general"}, cbi("ipv6-tools/general"), _("General Settings"), 10)
    entry({"admin", "services", "ipv6-tools", "openclash"}, cbi("ipv6-tools/openclash"), _("OpenClash Control"), 20)
    entry({"admin", "services", "ipv6-tools", "traffic"}, cbi("ipv6-tools/traffic"), _("Traffic Monitor"), 30)
    entry({"admin", "services", "ipv6-tools", "logs"}, template("ipv6-tools/logs"), _("Logs"), 40)

    -- API接口
    entry({"admin", "services", "ipv6-tools", "api", "status"}, call("api_status")).leaf = true
    entry({"admin", "services", "ipv6-tools", "api", "start"}, call("api_start")).leaf = true
    entry({"admin", "services", "ipv6-tools", "api", "stop"}, call("api_stop")).leaf = true
    entry({"admin", "services", "ipv6-tools", "api", "restart"}, call("api_restart")).leaf = true
    entry({"admin", "services", "ipv6-tools", "api", "connections"}, call("api_connections")).leaf = true
    entry({"admin", "services", "ipv6-tools", "api", "traffic"}, call("api_traffic")).leaf = true
    entry({"admin", "services", "ipv6-tools", "api", "validate"}, call("api_validate")).leaf = true
end

-- 获取IPv6-tools模块
local function get_ipv6_tools()
    return require "luci.model.ipv6-tools"
end

-- API: 获取状态
function api_status()
    local ipv6_tools = get_ipv6_tools()
    local status = ipv6_tools.get_service_status()

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        status = status,
        timestamp = os.time()
    })
end

-- API: 启动OpenClash
function api_start()
    local ipv6_tools = get_ipv6_tools()
    local success = ipv6_tools.start_openclash()

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = success,
        message = success and "OpenClash启动成功" or "OpenClash启动失败"
    })
end

-- API: 停止OpenClash
function api_stop()
    local ipv6_tools = get_ipv6_tools()
    local success = ipv6_tools.stop_openclash()

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = success,
        message = success and "OpenClash停止成功" or "OpenClash停止失败"
    })
end

-- API: 重启OpenClash
function api_restart()
    local ipv6_tools = get_ipv6_tools()
    local stop_success = ipv6_tools.stop_openclash()

    -- 等待一秒
    nixio.nanosleep(1, 0)

    local start_success = ipv6_tools.start_openclash()
    local success = stop_success and start_success

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = success,
        message = success and "OpenClash重启成功" or "OpenClash重启失败"
    })
end

-- API: 获取网络连接
function api_connections()
    local ipv6_tools = get_ipv6_tools()
    local connections = ipv6_tools.get_network_connections()

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        connections = connections,
        total = #connections,
        timestamp = os.time()
    })
end

-- API: 获取流量统计
function api_traffic()
    local ipv6_tools = get_ipv6_tools()
    local interface = luci.http.formvalue("interface") or "all"
    local traffic = ipv6_tools.get_traffic_stats(interface)

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        interface = interface,
        traffic = traffic,
        timestamp = os.time()
    })
end

-- API: 验证配置
function api_validate()
    local ipv6_tools = get_ipv6_tools()
    local errors = ipv6_tools.validate_config()

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        valid = #errors == 0,
        errors = errors
    })
end