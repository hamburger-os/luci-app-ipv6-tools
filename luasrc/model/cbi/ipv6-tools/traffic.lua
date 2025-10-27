-- IPv6 Tools Traffic Monitor Settings
-- Copyright (C) 2025
-- Licensed under GPL v3

local m, s, o

m = Map("ipv6-tools", translate("流量监控"), translate("配置网络流量监控功能"))

-- 流量监控设置
s = m:section(NamedSection, "traffic", "traffic", translate("监控设置"))
s.addremove = false

o = s:option(Flag, "enable", translate("启用流量监控"))
o.default = 1
o.rmempty = false

o = s:option(ListValue, "interface", translate("监控接口"))
o.default = "all"
o:value("all", translate("所有接口"))
-- 动态获取网络接口
for _, iface in ipairs(luci.sys.net.devices()) do
    if iface ~= "lo" then
        o:value(iface, iface)
    end
end
o.rmempty = false

o = s:option(Value, "min_traffic_kb", translate("最小流量阈值") .. " (KB)")
o.default = 10
o.datatype = "range(1,1000)"
o.rmempty = false

o = s:option(Value, "check_interval", translate("检查间隔") .. " (秒)")
o.default = 10
o.datatype = "range(5,300)"
o.rmempty = false

-- 实时流量显示
s = m:section(TypedSection, "ipv6-tools", translate("实时流量"))
s.addremove = false
s.anonymous = true

local traffic_display = s:option(DummyValue, "_traffic_display", translate("流量统计"))
traffic_display.template = "ipv6-tools/traffic_display"

-- 网络连接监控
s = m:section(TypedSection, "ipv6-tools", translate("网络连接"))
s.addremove = false
s.anonymous = true

local connections_display = s:option(DummyValue, "_connections_display", translate("当前连接"))
connections_display.template = "ipv6-tools/connections_display"

-- 流量历史
s = m:section(TypedSection, "ipv6-tools", translate("流量历史"))
s.addremove = false
s.anonymous = true

local traffic_chart = s:option(DummyValue, "_traffic_chart", translate("流量图表"))
traffic_chart.template = "ipv6-tools/traffic_chart"

-- 应用配置时的回调
m.on_commit = function()
    -- 重启服务以应用新配置
    luci.sys.call("/etc/init.d/ipv6-tools restart >/dev/null 2>&1 &")
end

return m