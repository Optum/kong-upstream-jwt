-- © Kong 2018
local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.kong-upstream-jwt.access"

local KongUpstreamJWTHandler = BasePlugin:extend()

function KongUpstreamJWTHandler:new()
  KongUpstreamJWTHandler.super.new(self, "kong-upstream-jwt")
end

function KongUpstreamJWTHandler:access(conf)
  KongUpstreamJWTHandler.super.access(self)
  access.execute(conf)
end

KongUpstreamJWTHandler.PRIORITY = 999 -- This plugin needs to run after auth plugins so it has access to `ngx.ctx.authenticated_consumer`
KongUpstreamJWTHandler.VERSION = "0.1.0"

return KongUpstreamJWTHandler
