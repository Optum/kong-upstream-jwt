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

KongUpstreamJWTHandler.PRIORITY = 2500
KongUpstreamJWTHandler.VERSION = "0.1.0"

return KongUpstreamJWTHandler
