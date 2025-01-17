local d = require "luci.dispatcher"
local ipkg = require("luci.model.ipkg")

local appname = "passwall"

local function is_finded(e)
    return luci.sys.exec("find /usr/*bin -iname " .. e .. " -type f") ~= "" and
               true or false
end

local function is_installed(e) return ipkg.installed(e) end

local ss_encrypt_method_list = {
    "rc4-md5", "aes-128-cfb", "aes-192-cfb", "aes-256-cfb", "aes-128-ctr",
    "aes-192-ctr", "aes-256-ctr", "bf-cfb", "camellia-128-cfb",
    "camellia-192-cfb", "camellia-256-cfb", "salsa20", "chacha20",
    "chacha20-ietf", -- aead
    "aes-128-gcm", "aes-192-gcm", "aes-256-gcm", "chacha20-ietf-poly1305",
    "xchacha20-ietf-poly1305"
}

local ssr_encrypt_method_list = {
    "none", "table", "rc2-cfb", "rc4", "rc4-md5", "rc4-md5-6", "aes-128-cfb",
    "aes-192-cfb", "aes-256-cfb", "aes-128-ctr", "aes-192-ctr", "aes-256-ctr",
    "bf-cfb", "camellia-128-cfb", "camellia-192-cfb", "camellia-256-cfb",
    "cast5-cfb", "des-cfb", "idea-cfb", "seed-cfb", "salsa20", "chacha20",
    "chacha20-ietf"
}

local ssr_protocol_list = {
    "origin", "verify_simple", "verify_deflate", "verify_sha1", "auth_simple",
    "auth_sha1", "auth_sha1_v2", "auth_sha1_v4", "auth_aes128_md5",
    "auth_aes128_sha1", "auth_chain_a", "auth_chain_b", "auth_chain_c",
    "auth_chain_d", "auth_chain_e", "auth_chain_f"
}
local ssr_obfs_list = {
    "plain", "http_simple", "http_post", "random_head", "tls_simple",
    "tls1.0_session_auth", "tls1.2_ticket_auth"
}

local v2ray_security_list = {"none", "auto", "aes-128-gcm", "chacha20-poly1305"}

local v2ray_header_type_list = {
    "none", "srtp", "utp", "wechat-video", "dtls", "wireguard"
}

m = Map(appname, translate("Node Config"))
m.redirect = d.build_url("admin", "vpn", "passwall")

s = m:section(NamedSection, arg[1], "nodes", "")
s.addremove = false
s.dynamic = false

remarks = s:option(Value, "remarks", translate("Node Remarks"))
remarks.default = translate("Remarks")
remarks.rmempty = false

type = s:option(ListValue, "type", translate("Type"))
if ((is_installed("redsocks2") or is_finded("redsocks2")) or
    (is_installed("ipt2socks") or is_finded("ipt2socks"))) then
    type:value("Socks5", translate("Socks5"))
end
if is_finded("ss-redir") then type:value("SS", translate("Shadowsocks")) end
if is_finded("ssr-redir") then type:value("SSR", translate("ShadowsocksR")) end
if is_installed("v2ray") then type:value("V2ray", translate("V2ray")) end
if is_installed("brook") or is_finded("brook") then
    type:value("Brook", translate("Brook"))
end
if is_installed("trojan") or is_finded("trojan") then
    type:value("Trojan", translate("Trojan"))
end

v2ray_protocol = s:option(ListValue, "v2ray_protocol",
                          translate("V2ray Protocol"))
v2ray_protocol:value("vmess", translate("Vmess"))
v2ray_protocol:depends("type", "V2ray")

address = s:option(Value, "address", translate("Address (Support Domain Name)"))
address.rmempty = false

use_ipv6 = s:option(Flag, "use_ipv6", translate("Use IPv6"))
use_ipv6.default = 0

port = s:option(Value, "port", translate("Port"))
port.datatype = "port"
port.rmempty = false

username = s:option(Value, "username", translate("Username"))
username:depends("type", "Socks5")

password = s:option(Value, "password", translate("Password"))
password.password = true
password:depends("type", "Socks5")
password:depends("type", "SS")
password:depends("type", "SSR")
password:depends("type", "Brook")
password:depends("type", "Trojan")

ss_encrypt_method = s:option(ListValue, "ss_encrypt_method",
                             translate("Encrypt Method"))
for a, t in ipairs(ss_encrypt_method_list) do ss_encrypt_method:value(t) end
ss_encrypt_method:depends("type", "SS")

ssr_encrypt_method = s:option(ListValue, "ssr_encrypt_method",
                              translate("Encrypt Method"))
for a, t in ipairs(ssr_encrypt_method_list) do ssr_encrypt_method:value(t) end
ssr_encrypt_method:depends("type", "SSR")

v2ray_security = s:option(ListValue, "v2ray_security",
                          translate("Encrypt Method"))
for a, t in ipairs(v2ray_security_list) do v2ray_security:value(t) end
v2ray_security:depends("type", "V2ray")

protocol = s:option(ListValue, "protocol", translate("Protocol"))
for a, t in ipairs(ssr_protocol_list) do protocol:value(t) end
protocol:depends("type", "SSR")

protocol_param = s:option(Value, "protocol_param", translate("Protocol_param"))
protocol_param:depends("type", "SSR")

obfs = s:option(ListValue, "obfs", translate("Obfs"))
for a, t in ipairs(ssr_obfs_list) do obfs:value(t) end
obfs:depends("type", "SSR")

obfs_param = s:option(Value, "obfs_param", translate("Obfs_param"))
obfs_param:depends("type", "SSR")

timeout = s:option(Value, "timeout", translate("Connection Timeout"))
timeout.datatype = "uinteger"
timeout.default = 300
timeout:depends("type", "SS")
timeout:depends("type", "SSR")

tcp_fast_open = s:option(ListValue, "tcp_fast_open", translate("TCP Fast Open"),
                         translate("Need node support required"))
tcp_fast_open:value("false")
tcp_fast_open:value("true")
tcp_fast_open:depends("type", "SS")
tcp_fast_open:depends("type", "SSR")
tcp_fast_open:depends("type", "Trojan")

ss_plugin = s:option(ListValue, "ss_plugin", translate("plugin"))
ss_plugin:value("none", translate("none"))
if is_finded("v2ray-plugin") then ss_plugin:value("v2ray-plugin") end
ss_plugin:depends("type", "SS")

ss_plugin_v2ray_opts = s:option(Value, "ss_plugin_v2ray_opts", translate("opts"))
ss_plugin_v2ray_opts:depends("ss_plugin", "v2ray-plugin")

use_kcp = s:option(Flag, "use_kcp", translate("Use Kcptun"),
                   "<span style='color:red'>" .. translate(
                       "Please confirm whether the Kcptun is installed. If not, please go to Rule Update download installation.") ..
                       "</span>")
use_kcp.default = 0
use_kcp:depends("type", "SS")
use_kcp:depends("type", "SSR")
use_kcp:depends("type", "Brook")

kcp_server = s:option(Value, "kcp_server", translate("Kcptun Server"))
kcp_server.placeholder = translate("Default:Current Server")
kcp_server:depends("use_kcp", "1")

kcp_use_ipv6 = s:option(Flag, "kcp_use_ipv6", translate("Use IPv6"))
kcp_use_ipv6.default = 0
kcp_use_ipv6:depends("use_kcp", "1")

kcp_port = s:option(Value, "kcp_port", translate("Kcptun Port"))
kcp_port.datatype = "port"
kcp_port:depends("use_kcp", "1")

kcp_opts = s:option(TextValue, "kcp_opts", translate("Kcptun Config"),
                    translate(
                        "--crypt aes192 --key abc123 --mtu 1350 --sndwnd 128 --rcvwnd 1024 --mode fast"))
kcp_opts.placeholder =
    "--crypt aes192 --key abc123 --mtu 1350 --sndwnd 128 --rcvwnd 1024 --mode fast"
kcp_opts:depends("use_kcp", "1")

v2ray_VMess_id = s:option(Value, "v2ray_VMess_id", translate("ID"))
v2ray_VMess_id.password = true
v2ray_VMess_id:depends("v2ray_protocol", "vmess")

v2ray_VMess_alterId = s:option(Value, "v2ray_VMess_alterId",
                               translate("Alter ID"))
v2ray_VMess_alterId:depends("v2ray_protocol", "vmess")

v2ray_VMess_level =
    s:option(Value, "v2ray_VMess_level", translate("User Level"))
v2ray_VMess_level.default = 1
v2ray_VMess_level:depends("type", "V2ray")

v2ray_stream_security = s:option(ListValue, "v2ray_stream_security",
                                 translate("Transport Layer Encryption"),
                                 translate(
                                     'Whether or not transport layer encryption is enabled, the supported options are "none" for unencrypted (default) and "TLS" for using TLS.'))
v2ray_stream_security:value("none", "none")
v2ray_stream_security:value("tls", "tls")
v2ray_stream_security:depends("type", "V2ray")

-- [[ TLS部分 ]] --
tls_serverName = s:option(Value, "tls_serverName", translate("Domain"))
tls_serverName:depends("v2ray_stream_security", "tls")

tls_allowInsecure = s:option(Flag, "tls_allowInsecure",
                             translate("allowInsecure"), translate(
                                 "Whether unsafe connections are allowed. When checked, V2Ray does not check the validity of the TLS certificate provided by the remote host."))
tls_allowInsecure.default = "0"
tls_allowInsecure.rmempty = false
tls_allowInsecure:depends("v2ray_stream_security", "tls")

v2ray_transport = s:option(ListValue, "v2ray_transport", translate("Transport"))
v2ray_transport:value("tcp", "TCP")
v2ray_transport:value("mkcp", "mKCP")
v2ray_transport:value("ws", "WebSocket")
v2ray_transport:value("h2", "HTTP/2")
v2ray_transport:value("ds", "DomainSocket")
v2ray_transport:value("quic", "QUIC")
v2ray_transport:depends("type", "V2ray")

-- [[ TCP部分 ]]--

-- TCP伪装
v2ray_tcp_guise = s:option(ListValue, "v2ray_tcp_guise",
                           translate("Camouflage Type"))
v2ray_tcp_guise:depends("v2ray_transport", "tcp")
v2ray_tcp_guise:value("none", "none")
v2ray_tcp_guise:value("http", "http")

-- HTTP域名
v2ray_tcp_guise_http_host = s:option(DynamicList, "v2ray_tcp_guise_http_host",
                                     translate("HTTP Host"))
v2ray_tcp_guise_http_host:depends("v2ray_tcp_guise", "http")

-- HTTP路径
v2ray_tcp_guise_http_path = s:option(DynamicList, "v2ray_tcp_guise_http_path",
                                     translate("HTTP Path"))
v2ray_tcp_guise_http_path:depends("v2ray_tcp_guise", "http")

-- [[ mKCP部分 ]]--

v2ray_mkcp_guise = s:option(ListValue, "v2ray_mkcp_guise",
                            translate("Camouflage Type"), translate(
                                '<br />none: default, no masquerade, data sent is packets with no characteristics.<br />srtp: disguised as an SRTP packet, it will be recognized as video call data (such as FaceTime).<br />utp: packets disguised as uTP will be recognized as bittorrent downloaded data.<br />wechat-video: packets disguised as WeChat video calls.<br />dtls: disguised as DTLS 1.2 packet.<br />wireguard: disguised as a WireGuard packet. (not really WireGuard protocol)'))
for a, t in ipairs(v2ray_header_type_list) do v2ray_mkcp_guise:value(t) end
v2ray_mkcp_guise:depends("v2ray_transport", "mkcp")

v2ray_mkcp_mtu = s:option(Value, "v2ray_mkcp_mtu", translate("KCP MTU"))
v2ray_mkcp_mtu:depends("v2ray_transport", "mkcp")

v2ray_mkcp_tti = s:option(Value, "v2ray_mkcp_tti", translate("KCP TTI"))
v2ray_mkcp_tti:depends("v2ray_transport", "mkcp")

v2ray_mkcp_uplinkCapacity = s:option(Value, "v2ray_mkcp_uplinkCapacity",
                                     translate("KCP uplinkCapacity"))
v2ray_mkcp_uplinkCapacity:depends("v2ray_transport", "mkcp")

v2ray_mkcp_downlinkCapacity = s:option(Value, "v2ray_mkcp_downlinkCapacity",
                                       translate("KCP downlinkCapacity"))
v2ray_mkcp_downlinkCapacity:depends("v2ray_transport", "mkcp")

v2ray_mkcp_congestion = s:option(Flag, "v2ray_mkcp_congestion",
                                 translate("KCP Congestion"))
v2ray_mkcp_congestion:depends("v2ray_transport", "mkcp")

v2ray_mkcp_readBufferSize = s:option(Value, "v2ray_mkcp_readBufferSize",
                                     translate("KCP readBufferSize"))
v2ray_mkcp_readBufferSize:depends("v2ray_transport", "mkcp")

v2ray_mkcp_writeBufferSize = s:option(Value, "v2ray_mkcp_writeBufferSize",
                                      translate("KCP writeBufferSize"))
v2ray_mkcp_writeBufferSize:depends("v2ray_transport", "mkcp")

-- [[ WebSocket部分 ]]--

v2ray_ws_host = s:option(Value, "v2ray_ws_host", translate("WebSocket Host"))
v2ray_ws_host:depends("v2ray_transport", "ws")

v2ray_ws_path = s:option(Value, "v2ray_ws_path", translate("WebSocket Path"))
v2ray_ws_path:depends("v2ray_transport", "ws")

-- [[ HTTP/2部分 ]]--

v2ray_h2_host = s:option(DynamicList, "v2ray_h2_host", translate("HTTP/2 Host"))
v2ray_h2_host:depends("v2ray_transport", "h2")

v2ray_h2_path = s:option(Value, "v2ray_h2_path", translate("HTTP/2 Path"))
v2ray_h2_path:depends("v2ray_transport", "h2")

-- [[ DomainSocket部分 ]]--

v2ray_ds_path = s:option(Value, "v2ray_ds_path", "Path", translate(
                             "A legal file path. This file must not exist before running V2Ray."))
v2ray_ds_path:depends("v2ray_transport", "ds")

-- [[ QUIC部分 ]]--
v2ray_quic_security = s:option(ListValue, "v2ray_quic_security",
                               translate("Encrypt Method"))
v2ray_quic_security:value("none")
v2ray_quic_security:value("aes-128-gcm")
v2ray_quic_security:value("chacha20-poly1305")
v2ray_quic_security:depends("v2ray_transport", "quic")

v2ray_quic_key = s:option(Value, "v2ray_quic_key",
                          translate("Encrypt Method") .. translate("Key"))
v2ray_quic_key:depends("v2ray_transport", "quic")

v2ray_quic_guise = s:option(ListValue, "v2ray_quic_guise",
                            translate("Camouflage Type"))
for a, t in ipairs(v2ray_header_type_list) do v2ray_quic_guise:value(t) end
v2ray_quic_guise:depends("v2ray_transport", "quic")

-- [[ 其它 ]]--

v2ray_mux = s:option(Flag, "v2ray_mux", translate("Mux"))
v2ray_mux:depends("type", "V2ray")

v2ray_mux_concurrency = s:option(Value, "v2ray_mux_concurrency",
                                 translate("Mux Concurrency"))
v2ray_mux_concurrency.default = 8
v2ray_mux_concurrency:depends("v2ray_mux", "1")

-- [[ 当作为TCP节点时，是否同时开启socks代理 ]]
v2ray_tcp_socks = s:option(Flag, "v2ray_tcp_socks", translate("TCP Open Socks"),
                           translate(
                               "When using this TCP node, whether to open the socks proxy at the same time"))
v2ray_tcp_socks.default = 0
v2ray_tcp_socks:depends("type", "V2ray")

v2ray_tcp_socks_port = s:option(Value, "v2ray_tcp_socks_port",
                                "Socks5 " .. translate("Port"),
                                translate("Do not conflict with other ports"))
v2ray_tcp_socks_port.datatype = "port"
v2ray_tcp_socks_port.default = 1080
v2ray_tcp_socks_port:depends("v2ray_tcp_socks", "1")

v2ray_tcp_socks_auth = s:option(ListValue, "v2ray_tcp_socks_auth",
                                translate("Socks for authentication"),
                                translate(
                                    'Socks protocol authentication, support anonymous and password.'))
v2ray_tcp_socks_auth:value("noauth", translate("anonymous"))
v2ray_tcp_socks_auth:value("password", translate("User Password"))
v2ray_tcp_socks_auth:depends("v2ray_tcp_socks", "1")

v2ray_tcp_socks_auth_username = s:option(Value, "v2ray_tcp_socks_auth_username",
                                         "Socks5 " .. translate("Username"))
v2ray_tcp_socks_auth_username:depends("v2ray_tcp_socks_auth", "password")

v2ray_tcp_socks_auth_password = s:option(Value, "v2ray_tcp_socks_auth_password",
                                         "Socks5 " .. translate("Password"))
v2ray_tcp_socks_auth_password:depends("v2ray_tcp_socks_auth", "password")

-- [[ Trojan Cert ]]--
trojan_verify_cert = s:option(Flag, "trojan_verify_cert",
                              translate("Trojan Verify Cert"))
trojan_verify_cert:depends("type", "Trojan")

trojan_cert_path = s:option(Value, "trojan_cert_path",
                            translate("Trojan Cert Path"))
trojan_cert_path.default = ""
trojan_cert_path:depends("trojan_verify_cert", "1")

-- v2ray_insecure = s:option(Flag, "v2ray_insecure", translate("allowInsecure"))
-- v2ray_insecure:depends("type", "V2ray")

function rmempty_restore()
    password.rmempty = true
    timeout.rmempty = true
    tcp_fast_open.rmempty = true
    v2ray_protocol.rmempty = true
    v2ray_VMess_id.rmempty = true
    v2ray_VMess_alterId.rmempty = true
end

type.validate = function(self, value)
    rmempty_restore()
    if value == "SS" then
        password.rmempty = false
        timeout.rmempty = false
        tcp_fast_open.rmempty = false
    elseif value == "SSR" then
        password.rmempty = false
        timeout.rmempty = false
        tcp_fast_open.rmempty = false
    elseif value == "V2ray" then
        v2ray_protocol.rmempty = false
        v2ray_VMess_id.rmempty = false
        v2ray_VMess_alterId.rmempty = false
    elseif value == "Brook" then
        password.rmempty = false
    elseif value == "Trojan" then
        password.rmempty = false
        tcp_fast_open.rmempty = false
    end
    return value
end

v2ray_transport.validate = function(self, value) return value end

return m
