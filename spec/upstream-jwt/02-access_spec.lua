local helpers = require "spec.helpers"


for _, strategy in helpers.each_strategy() do
  describe("upstream-jwt: (access) [#" .. strategy .. "]", function()
    local client, consumer

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy, nil, { "upstream-jwt" })

      -- Inject a loopback service. Test requests are looped back and will hit
      -- this route, which will then validate the JWT
      local route_JWT = bp.routes:insert({
        hosts = { "localhost" },
      })
      bp.plugins:insert {
        name = "jwt",
        route = { id = route_JWT.id },
        config = {
          header_names = { "My-Authorization" },
          key_claim_name = "iss", -- the claim whose value to use to look up the consumer secret
        },
      }
      consumer = bp.consumers:insert {
        username = "tieske",
        custom_id = "also_tieske",
      }
      bp.jwt_secrets:insert {
        consumer       = { id = consumer.id },
        algorithm      = "RS256",
        key            = "source-kong",
        rsa_public_key = assert(helpers.utils.readfile("/kong-plugin/testcert.pem"))
      }

      -- Service that loops back to the JWT route/plugin above
      local service_loopback = bp.services:insert({
        host = "localhost",
        port = helpers.get_proxy_port(),
        protocol = "http",
      })
      local route1 = bp.routes:insert({
        service = { id = service_loopback.id },
        hosts = { "test1.com" },
      })
      bp.plugins:insert {
        name = "upstream-jwt",
        route = { id = route1.id },
        config = {
          issuer = "source-kong",
          private_key_location = "/kong-plugin/testcert-private.pem",
          public_key_location = "/kong-plugin/testcert.pem",
          key_id = nil,  -- kid header value in JWT
          header = "My-Authorization",
          include_credential_type = true,  -- include "Bearer " in header
        },
      }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled,upstream-jwt",
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)



    it("a valid JWT passes", function()
      local r = client:get("/request", {
        headers = {
          host = "test1.com"
        }
      })
      assert.response(r).has.status(200)
      assert.equal('also_tieske', assert.request(r).has.header("x-consumer-custom-id"))
      assert.equal(consumer.id,   assert.request(r).has.header("x-consumer-id"))
      assert.equal('tieske',      assert.request(r).has.header("x-consumer-username"))
      assert.equal('source-kong', assert.request(r).has.header("x-credential-identifier"))
    end)

  end)
end
