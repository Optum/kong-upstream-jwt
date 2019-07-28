-- © Optum 2018
local resty_sha256 = require "resty.sha256"
local str = require "resty.string"
local singletons = require "kong.singletons"
local pl_file = require "pl.file"
local json = require "cjson"
local openssl_digest = require "openssl.digest"
local openssl_pkey = require "openssl.pkey"
local table_concat = table.concat
local encode_base64 = ngx.encode_base64
local env_private_key_location = os.getenv("KONG_SSL_CERT_KEY")
local env_public_key_location = os.getenv("KONG_SSL_CERT_DER")
local utils = require "kong.tools.utils"
local _M = {}

--- Get the private key location either from the environment or from configuration
-- @param conf the kong configuration
-- @return the private key location
local function get_private_key_location(conf)
  if env_private_key_location then
    return env_private_key_location
  end
  return conf.private_key_location
end

--- Get the public key location either from the environment or from configuration
-- @param conf the kong configuration
-- @return the public key location
local function get_public_key_location(conf)
  if env_public_key_location then
    return env_public_key_location
  end
  return conf.public_key_location
end

--- base 64 encoding
-- @param input String to base64 encode
-- @return Base64 encoded string
local function b64_encode(input)
  local result = encode_base64(input)
  result = result:gsub("+", "-"):gsub("/", "_"):gsub("=", "")
  return result
end

--- Read contents of file from given location
-- @param file_location the file location
-- @return the file contents
local function read_from_file(file_location)
  local content, err = pl_file.read(file_location)
  if not content then
    ngx.log(ngx.ERR, "Could not read file contents", err)
    return nil, err
  end
  return content
end

--- Get the Kong key either from cache or the given `location`
-- @param key the cache key to lookup first
-- @param location the location of the key file
-- @return the key contents
local function get_kong_key(key, location)
  -- This will add a non expiring TTL on this cached value
  -- https://github.com/thibaultcha/lua-resty-mlcache/blob/master/README.md
  local pkey, err = singletons.cache:get(key, { ttl = 0 }, read_from_file, location)

  if err then
    ngx.log(ngx.ERR, "Could not retrieve pkey: ", err)
    return
  end

  return pkey
end

--- Base64 encode the JWT token
-- @param payload the payload of the token
-- @param key the key to sign the token with
-- @return the encoded JWT token
local function encode_jwt_token(conf, payload, key)
  local header = {
    typ = "JWT",
    alg = "RS256",
    x5c = {
      b64_encode(get_kong_key("pubder", get_public_key_location(conf)))
    }
  }
  if conf.key_id then
    header.kid = conf.key_id
  end
  local segments = {
    b64_encode(json.encode(header)),
    b64_encode(json.encode(payload))
  }
  local signing_input = table_concat(segments, ".")
  local signature = openssl_pkey.new(key):sign(openssl_digest.new("sha256"):update(signing_input))
  segments[#segments+1] = b64_encode(signature)
  return table_concat(segments, ".")
end

--- Build the JWT token payload based off the `payload_hash`
-- @param conf the configuration
-- @param payload_hash the payload hash
-- @return the JWT payload (table)
local function build_jwt_payload(conf, payload_hash)
  local current_time = ngx.time() -- Much better performance improvement over os.time()
  local payload = {
    exp = current_time + 60,
    jti = utils.uuid(),
    payloadhash = payload_hash
  }

  if conf.issuer then
    payload.iat = current_time
    payload.iss = conf.issuer
  end

  if ngx.ctx.service then
    payload.aud = ngx.ctx.service.name
  end

  local consumer = kong.client.get_consumer()
  if consumer then
    payload.consumerid = consumer.id
    payload.consumername = consumer.username
  end

  return payload
end

--- Build the payload hash
-- @return SHA-256 hash of the request body data
local function build_payload_hash()
  ngx.req.read_body()
  local req_body  = ngx.req.get_body_data()
  local payload_digest = ""
  if req_body then
    local sha256 = resty_sha256:new()
    sha256:update(req_body)
    payload_digest = sha256:final()
  end
  return str.to_hex(payload_digest)
end

local function build_header_value(conf, jwt)
  if conf.include_credential_type then
    return "Bearer " .. jwt
  else
    return jwt
  end
end

--- Add the JWT header to the request
-- @param conf the configuration
local function add_jwt_header(conf)
  local payload_hash = build_payload_hash()
  local payload = build_jwt_payload(conf, payload_hash)
  local kong_private_key = get_kong_key("pkey", get_private_key_location(conf))
  local jwt = encode_jwt_token(conf, payload, kong_private_key)
  ngx.req.set_header(conf.header, build_header_value(conf, jwt))
end

--- Execute the script
-- @param conf kong configuration
function _M.execute(conf)
  add_jwt_header(conf)
end

return _M