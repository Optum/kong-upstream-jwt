local access = require "kong.plugins.kong-upstream-jwt.access"

local KongUpstreamJWTHandler = {}

function KongUpstreamJWTHandler:access(conf)
  access.execute(conf)
end

KongUpstreamJWTHandler.PRIORITY = 999 -- This plugin needs to run after auth plugins so it has access to `ngx.ctx.authenticated_consumer`
KongUpstreamJWTHandler.VERSION = "1.0"

return KongUpstreamJWTHandler
