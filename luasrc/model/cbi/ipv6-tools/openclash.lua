-- IPv6 Tools OpenClash Control Settings
-- Copyright (C) 2025
-- Licensed under GPL v3

local m, s, o

m = Map("ipv6-tools", translate("OpenClash自动控制"), translate("配置OpenClash的自动开启和关闭功能"))

-- OpenClash自动控制设置
s = m:section(NamedSection, "openclash", "auto_control", translate("自动控制设置"))
s.addremove = false

o = s:option(Flag, "enable", translate("启用自动控制"))
o.default = 1
o.rmempty = false

o = s:option(ListValue, "check_method", translate("检测方式"))
o.default = "domain"
o:value("domain", translate("域名检测"))
o:value("ip", translate("IP地址检测"))
o:value("both", translate("域名和IP检测"))
o.rmempty = false

o = s:option(TextValue, "domain_list", translate("需要VPN的域名列表"))
o.default = ""
o.description = translate("每行一个域名，支持通配符，例如: google.com, *.youtube.com")
o.rows = 8
o.rmempty = true

o = s:option(TextValue, "ip_list", translate("需要VPN的IP地址列表"))
o.default = ""
o.description = translate("每行一个IP地址或IP段，例如: 8.8.8.8, 1.1.1.0/24")
o.rows = 8
o.rmempty = true

-- 命令配置
s = m:section(NamedSection, "openclash", "auto_control", translate("命令配置"))
s.addremove = false

o = s:option(Value, "start_command", translate("启动命令"))
o.default = "/etc/init.d/openclash restart"
o.rmempty = false

o = s:option(Value, "stop_command", translate("停止命令"))
o.default = "/etc/init.d/openclash stop"
o.rmempty = false

o = s:option(Value, "status_command", translate("状态检查命令"))
o.default = "/etc/init.d/openclash status"
o.rmempty = false

-- 测试区域
s = m:section(TypedSection, "ipv6-tools", translate("测试功能"))
s.addremove = false
s.anonymous = true

local test_domain = s:option(Value, "_test_domain", translate("测试域名"))
test_domain.placeholder = "google.com"

local test_result = s:option(DummyValue, "_test_result", translate("测试结果"))
test_result.template = "ipv6-tools/test_result"

-- 预设规则
s = m:section(TypedSection, "ipv6-tools", translate("预设规则"))
s.addremove = false
s.anonymous = true

local preset_rules = s:option(DummyValue, "_preset_rules", translate("常用规则"))
preset_rules.template = "ipv6-tools/preset_rules"

-- 应用配置时的回调
m.on_commit = function()
    -- 重启服务以应用新配置
    luci.sys.call("/etc/init.d/ipv6-tools restart >/dev/null 2>&1 &")
end

return m