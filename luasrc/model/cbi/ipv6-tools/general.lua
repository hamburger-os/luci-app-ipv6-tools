-- IPv6 Tools General Settings
-- Copyright (C) 2025
-- Licensed under GPL v3

local m, s, o

m = Map("ipv6-tools", translate("IPv6 Tools"), translate("IPv6工具包，提供OpenClash自动控制等功能"))

-- 全局设置
s = m:section(NamedSection, "global", "ipv6-tools", translate("全局设置"))
s.addremove = false

o = s:option(Flag, "enable", translate("启用服务"))
o.default = 0
o.rmempty = false

o = s:option(Value, "debug_level", translate("调试级别"))
o.default = 1
o.datatype = "range(0,5)"
o.rmempty = false

o = s:option(Value, "check_interval", translate("检查间隔") .. " (秒)")
o.default = 5
o.datatype = "range(1,300)"
o.rmempty = false

o = s:option(Value, "idle_timeout", translate("空闲超时") .. " (秒)")
o.default = 300
o.datatype = "range(60,3600)"
o.rmempty = false

o = s:option(Value, "startup_delay", translate("启动延迟") .. " (秒)")
o.default = 10
o.datatype = "range(0,300)"
o.rmempty = false

-- 服务状态显示
s = m:section(TypedSection, "ipv6-tools", translate("服务状态"))
s.addremove = false
s.anonymous = true

-- 创建状态显示区域
local status = s:option(DummyValue, "_status", translate("当前状态"))
status.template = "ipv6-tools/status"

-- 服务控制按钮
local control = s:option(DummyValue, "_control", translate("服务控制"))
control.template = "ipv6-tools/control"

-- 日志设置
s = m:section(NamedSection, "log", "log", translate("日志设置"))
s.addremove = false

o = s:option(Flag, "enable", translate("启用日志"))
o.default = 1
o.rmempty = false

o = s:option(Value, "log_file", translate("日志文件路径"))
o.default = "/var/log/ipv6-tools.log"
o.rmempty = false

o = s:option(Value, "max_size", translate("最大文件大小") .. " (KB)")
o.default = 100
o.datatype = "range(10,1024)"
o.rmempty = false

o = s:option(ListValue, "log_level", translate("日志级别"))
o.default = "info"
o:value("debug", translate("调试"))
o:value("info", translate("信息"))
o:value("warning", translate("警告"))
o:value("error", translate("错误"))

-- 应用配置时的回调
m.on_commit = function()
    -- 重启服务以应用新配置
    luci.sys.call("/etc/init.d/ipv6-tools restart >/dev/null 2>&1 &")
end

return m