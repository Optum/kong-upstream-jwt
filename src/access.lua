-- © Optum 2018
local resty_sha256 = require "resty.sha256"
local str = require "resty.string"
local singletons = require "kong.singletons"
local public_key_der_location =  os.getenv("KONG_SSL_CERT_DER")
local private_key_location =  os.getenv("KONG_SSL_CERT_KEY")
local jwt_issuer =  os.getenv("KONG_JWT_ISSUER")
local jwt_audience =  os.getenv("KONG_JWT_AUDIENCE")
local pl_file = require "pl.file"
local json = require "cjson"
local openssl_digest = require "openssl.digest"
local openssl_pkey = require "openssl.pkey"
local table_concat = table.concat
local encode_base64 = ngx.encode_base64
local _M = {}

--- base 64 encoding
-- @param input String to base64 encode
-- @return Base64 encoded string
local function b64_encode(input)
  local result = encode_base64(input)
  result = result:gsub("+", "-"):gsub("/", "_"):gsub("=", "")
  return result
end

--- Read contents of file from given `file_location`
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
local function encode_jwt_token(payload, key)
  local header = {
    typ = "JWT",
    alg = "RS256",
    x5c = {
      b64_encode(get_kong_key("pubder",public_key_der_location))
    }
  }
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
-- @param payload_hash the payload hash
-- @return the JWT payload (table)
local function build_jwt_payload(payload_hash)
  local current_time = ngx.time() -- much better performance improvement over os.time()
  local payload = {
    exp = current_time + 60,
    payloadhash = payload_hash
  }

  if jwt_issuer ~= nil then
    payload.iat = current_time
    payload.iss = jwt_issuer
  end

  if jwt_audience ~= nil then
    payload.aud = jwt_audience
  end

  -- no need to go any further if we don't have an `authenticated_consumer`
  if ngx.ctx.authenticated_consumer == nil then
    return payload
  end

  if ngx.ctx.authenticated_consumer.id ~= nil then
    payload.sub = ngx.ctx.authenticated_consumer.id
  end

  if ngx.ctx.authenticated_consumer.username ~= nil then
    payload.username = ngx.ctx.authenticated_consumer.username
  end

  return payload
end

--- Build the payload hash
-- @return SHA-256 hash of the request body data
local function build_payload_hash()
  ngx.req.read_body()
  local req_body  = ngx.req.get_body_data()
  local payload_digest = ""
  if req_body ~= nil then
    local sha256 = resty_sha256:new()
    sha256:update(req_body)
    payload_digest = sha256:final()
  end
  return str.to_hex(payload_digest)
end

--- Add the JWT header to the reqeust
-- @param conf the configuration
local function add_jwt_header(conf)
  local payload_hash = build_payload_hash()
  local payload = build_jwt_payload(payload_hash)
  local kong_pkey = get_kong_key("pkey", private_key_location)
  local jwt = encode_jwt_token(payload, kong_pkey)
  ngx.req.set_header("JWT", jwt)
end

function _M.execute(conf)
  add_jwt_header(conf)
end

return _M
