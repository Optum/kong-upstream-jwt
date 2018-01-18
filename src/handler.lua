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

-- Set a low priority, because 'AUTH' plugins run with priority 1000, and we don't want to strip the Authorization header before the request reaches OAuth
KongUpstreamJWTHandler.PRIORITY = 1200
KongUpstreamJWTHandler.VERSION = "0.1.0"

return KongUpstreamJWTHandler
