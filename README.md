# luci-app-ipv6-tools

IPv6工具包LuCI应用程序，提供OpenClash自动控制功能和网络监控工具。

## 📋 项目简介

luci-app-ipv6-tools是一个专为OpenWrt路由器设计的LuCI应用程序，主要功能是根据网络访问需求智能控制OpenClash代理服务。当检测到用户访问需要VPN的网站时，会自动启动OpenClash；在一段时间没有VPN访问需求时，会自动关闭OpenClash以节省系统资源。

## ✨ 核心功能

### 🤖 OpenClash自动控制
- **智能检测**: 监控DNS查询和网络连接，识别需要VPN的访问
- **自动启动**: 检测到VPN需求时自动启动OpenClash服务
- **自动关闭**: 空闲超时后自动关闭OpenClash以节省资源
- **状态同步**: 实时同步OpenClash运行状态

### 🌐 规则匹配系统
- **域名匹配**: 支持精确域名和通配符域名匹配
- **IP地址匹配**: 支持单个IP和IP段匹配
- **灵活配置**: 可选择域名检测、IP检测或两者结合

### 📊 网络监控
- **实时流量**: 监控网络接口的实时流量数据
- **连接监控**: 显示当前活动的网络连接
- **流量统计**: 记录历史流量数据
- **接口选择**: 可选择监控特定网络接口或全部接口

### 🖥️ Web管理界面
- **状态显示**: 实时显示服务状态和OpenClash状态
- **手动控制**: 提供启动、停止、重启OpenClash的手动控制按钮
- **配置管理**: 直观的配置界面，支持所有参数设置
- **日志查看**: 内置日志查看器，支持多行显示和实时刷新

### 📝 日志系统
- **分级日志**: 支持调试、信息、警告、错误四个级别
- **文件轮转**: 自动管理日志文件大小
- **详细记录**: 记录所有操作和系统事件

## 🔧 技术规格

| 项目 | 规格 |
|------|------|
| **支持架构** | all (所有架构) |
| **依赖包** | luci, luci-lib-nixio |
| **推荐包** | openclash |
| **包大小** | ~150KB (源码) |
| **运行内存** | <1MB |
| **存储空间** | ~200KB |
| **许可证** | GPL-3.0+ |

## 📦 安装说明

### 系统要求
- OpenWrt 19.07 或更高版本
- LuCI Web界面
- 至少2MB可用存储空间
- OpenClash (用于自动控制功能)

### 安装方法

#### 方法1: SDK编译安装
```bash
# 1. 进入OpenWrt SDK目录
cd /path/to/openwrt-sdk

# 2. 更新feeds
./scripts/feeds update luci

# 3. 安装包
./scripts/feeds install luci-app-ipv6-tools

# 4. 编译包 (可选)
make package/feeds/luci/luci-app-ipv6-tools/compile

# 5. 编译固件 (包含此包)
make
```

#### 方法2: IPK包安装
```bash
# 1. 下载编译好的IPK包
wget https://github.com/your-repo/luci-app-ipv6-tools/releases/download/v1.0.0/luci-app-ipv6-tools_1.0.0-1_all.ipk

# 2. 上传到路由器并安装
scp luci-app-ipv6-tools_1.0.0-1_all.ipk root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "opkg install /tmp/luci-app-ipv6-tools_1.0.0-1_all.ipk"

# 3. 重启LuCI
/etc/init.d/uhttpd restart
```

#### 方法3: 开发环境安装
```bash
# 克隆源码到feeds目录
git clone https://github.com/your-repo/luci-app-ipv6-tools.git feeds/luci/applications/luci-app-ipv6-tools

# 更新和安装
./scripts/feeds update luci
./scripts/feeds install luci-app-ipv6-tools
```

## ⚙️ 配置说明

### 基础配置 (General Settings)

访问路径: **LuCI → 服务 → IPv6 Tools → General Settings**

| 选项 | 说明 | 默认值 |
|------|------|--------|
| **启用服务** | 启用IPv6 Tools服务 | 关闭 |
| **调试级别** | 日志详细程度 (0-5) | 1 |
| **检查间隔** | 检测间隔时间 (秒) | 5 |
| **空闲超时** | 无活动后超时时间 (秒) | 300 |
| **启动延迟** | 系统启动后延迟时间 (秒) | 10 |

### OpenClash控制 (OpenClash Control)

访问路径: **LuCI → 服务 → IPv6 Tools → OpenClash Control**

| 选项 | 说明 | 示例 |
|------|------|------|
| **启用自动控制** | 开启自动控制功能 | 开启 |
| **检测方式** | 选择检测方法 | 域名检测 |
| **域名列表** | 需要VPN的域名 | `google.com,youtube.com,*.facebook.com` |
| **IP地址列表** | 需要VPN的IP地址 | `8.8.8.8,1.1.1.0/24` |
| **启动命令** | OpenClash启动命令 | `/etc/init.d/openclash restart` |
| **停止命令** | OpenClash停止命令 | `/etc/init.d/openclash stop` |
| **状态命令** | OpenClash状态检查命令 | `/etc/init.d/openclash status` |

### 流量监控 (Traffic Monitor)

访问路径: **LuCI → 服务 → IPv6 Tools → Traffic Monitor**

| 选项 | 说明 | 默认值 |
|------|------|--------|
| **启用流量监控** | 开启流量监控功能 | 开启 |
| **监控接口** | 选择监控的网络接口 | all |
| **最小流量阈值** | 触发检测的最小流量 (KB) | 10 |
| **检查间隔** | 流量检查间隔 (秒) | 10 |

### 日志配置

| 选项 | 说明 | 默认值 |
|------|------|--------|
| **启用日志** | 开启日志记录功能 | 开启 |
| **日志文件路径** | 日志文件存储位置 | `/var/log/ipv6-tools.log` |
| **最大文件大小** | 日志文件最大大小 (KB) | 100 |
| **日志级别** | 记录的最低日志级别 | info |

## 🚀 使用指南

### 首次使用

1. **安装应用**: 按照上述安装方法完成安装
2. **访问界面**: 浏览器访问 `http://192.168.1.1/cgi-bin/luci/admin/services/ipv6-tools`
3. **基本配置**: 在"General Settings"中启用服务
4. **配置规则**: 在"OpenClash Control"中配置域名/IP规则
5. **启动服务**: 保存配置并重启服务

### 日常使用

#### 查看状态
- 在主界面查看当前服务状态
- 查看OpenClash运行状态
- 查看最后一次活动时间

#### 手动控制
- 使用控制按钮手动启动/停止OpenClash
- 重启服务
- 刷新状态

#### 查看日志
- 访问"Logs"页面查看详细日志
- 选择显示的日志行数
- 刷新或清空日志

### 自动控制工作流程

1. **监控阶段**: 系统定期检查网络连接和DNS查询
2. **规则匹配**: 将访问的域名/IP与规则列表进行匹配
3. **启动检测**: 检测到匹配项且OpenClash未运行时，启动OpenClash
4. **活动监控**: 监控网络活动，更新最后活动时间
5. **空闲检测**: 检查空闲时间是否超过设定阈值
6. **自动关闭**: 超时后自动关闭OpenClash

## 🔍 故障排除

### 常见问题及解决方案

#### 1. 服务无法启动

**症状**: 服务状态显示"已停止"或"未知状态"

**解决方案**:
```bash
# 检查脚本权限
ls -la /usr/share/ipv6-tools/ipv6-tools.sh
chmod +x /usr/share/ipv6-tools/ipv6-tools.sh

# 检查服务脚本权限
ls -la /etc/init.d/ipv6-tools
chmod +x /etc/init.d/ipv6-tools

# 手动启动测试
/etc/init.d/ipv6-tools start

# 查看系统日志
logread | grep ipv6-tools
```

#### 2. OpenClash自动控制不工作

**症状**: OpenClash不会自动启动或停止

**解决方案**:
```bash
# 检查OpenClash是否安装
ls -la /etc/init.d/openclash

# 测试OpenClash命令
/etc/init.d/openclash status
/etc/init.d/openclash restart
/etc/init.d/openclash stop

# 检查配置
uci show ipv6-tools | grep openclash

# 查看详细日志
tail -f /var/log/ipv6-tools.log
```

#### 3. 域名检测不准确

**症状**: 访问某些网站时OpenClash没有自动启动

**解决方案**:
- 检查域名列表格式是否正确
- 确认DNS查询日志可访问
- 调整检测间隔时间
- 启用调试模式查看详细检测过程

#### 4. 性能问题

**症状**: 系统运行缓慢或响应延迟

**解决方案**:
```bash
# 增加检查间隔
uci set ipv6-tools.@global[0].check_interval=10
uci commit ipv6-tools

# 降低日志级别
uci set ipv6-tools.@global[0].debug_level=0
uci set ipv6-tools.@log[0].log_level='warning'
uci commit ipv6-tools

# 重启服务
/etc/init.d/ipv6-tools restart
```

### 调试模式

启用详细调试模式:
```bash
# 设置调试级别为3 (详细)
uci set ipv6-tools.@global[0].debug_level=3
uci commit ipv6-tools

# 重启服务
/etc/init.d/ipv6-tools restart

# 实时查看日志
tail -f /var/log/ipv6-tools.log
```

### 手动测试

测试脚本功能:
```bash
# 测试状态检查
/usr/share/ipv6-tools/ipv6-tools.sh status

# 测试启动OpenClash
/usr/share/ipv6-tools/ipv6-tools.sh start

# 测试停止OpenClash
/usr/share/ipv6-tools/ipv6-tools.sh stop

# 测试监控功能
/usr/share/ipv6-tools/ipv6-tools.sh monitor
```

## 📁 文件结构

```
luci-app-ipv6-tools/
├── 📄 README.md                          # 本说明文档
├── 📄 Makefile                          # 编译配置文件
├── 📁 luasrc/                           # Lua源代码目录
│   ├── 📁 controller/
│   │   └── 📄 ipv6-tools.lua           # LuCI控制器
│   ├── 📁 model/
│   │   ├── 📄 ipv6-tools.lua           # 核心功能模块
│   │   └── 📁 cbi/
│   │       └── 📁 ipv6-tools/
│   │           ├── 📄 general.lua      # 通用设置页面
│   │           ├── 📄 openclash.lua    # OpenClash控制页面
│   │           └── 📄 traffic.lua      # 流量监控页面
│   └── 📁 view/
│       └── 📁 ipv6-tools/
│           ├── 📄 status.htm           # 状态显示模板
│           ├── 📄 control.htm          # 控制按钮模板
│           └── 📄 logs.htm             # 日志查看模板
├── 📁 root/                             # 目标系统文件目录
│   ├── 📁 etc/
│   │   ├── 📁 config/
│   │   │   └── 📄 ipv6-tools           # UCI配置文件
│   │   ├── 📁 init.d/
│   │   │   └── 📄 ipv6-tools           # 服务管理脚本
│   │   └── 📁 uci-defaults/
│   │       └── 📄 99-ipv6-tools        # 默认配置脚本
│   └── 📁 usr/
│       └── 📁 share/
│           └── 📁 ipv6-tools/
│               ├── 📄 ipv6-tools.sh    # 核心检测脚本
│               └── 📁 acl.d/
│                   └── 📄 ipv6-tools.json # 权限配置文件
```

## 🛠️ 开发信息

### 开发环境
- **框架**: OpenWrt LuCI
- **语言**: Lua, Shell Script
- **版本**: 1.0.0
- **许可证**: GPL-3.0+

### 代码统计
- **总文件数**: 15个
- **代码行数**: 1600+ 行
- **Lua代码**: 800+ 行
- **Shell脚本**: 600+ 行
- **配置文件**: 200+ 行

### 维护者
- **作者**: Your Name
- **邮箱**: your.email@example.com
- **主页**: https://github.com/your-repo/luci-app-ipv6-tools

## 🤝 贡献指南

我们欢迎任何形式的贡献！

### 报告问题
1. 在GitHub上创建Issue
2. 详细描述问题现象
3. 提供系统环境信息
4. 附上相关日志文件

### 提交代码
1. Fork本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

### 开发规范
- 遵循Lua编码规范
- 添加必要的注释
- 测试功能正常
- 更新相关文档

## 📄 许可证

本项目采用GPL-3.0+许可证。详情请参见[LICENSE](LICENSE)文件。

## 🙏 致谢

- 感谢OpenWrt社区提供的优秀框架
- 感谢OpenClash项目提供的代理解决方案
- 感谢所有测试用户的反馈和建议

## 📞 支持

如果您在使用过程中遇到问题，可以通过以下方式获取帮助：

- 📧 邮箱: your.email@example.com
- 🐛 问题反馈: https://github.com/your-repo/luci-app-ipv6-tools/issues
- 💬 讨论区: https://github.com/your-repo/luci-app-ipv6-tools/discussions

---

**注意**: 本工具仅用于合法的网络访问需求，请遵守当地法律法规。