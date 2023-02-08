package = "kong-upstream-jwt"
version = "1.3-0"
source = {
   url = "git+https://github.com/Optum/kong-upstream-jwt.git"
}
description = {
   summary = "A plugin for Kong which adds a signed JWT to HTTP Headers of outgoing requests",
   detailed = [[API Providers require a means of cryptographically validating that requests they receive were: A. proxied by Kong, and B. not tampered with during transmission from Kong -> API Provider. This token accomplishes both as follows:

  1. **Authentication** & **Authorization** - Provided by means of JWT signature validation. The API Provider will validate the signature on the JWT token (which is generating using Kong's RSA x509 private key), using Kong's public key. This public key can be maintained in a keystore, or sent with the token - provided API providers validate the signature chain against their truststore.
  2. **Non-Repudiation** - SHA256 is used to hash the body of the HTTP Request Body, and the resulting digest is included in the `payloadhash` element of the JWT body. API Providers will take the SHA256 hash of the HTTP Request Body, and compare the digest to that found in the JWT. If they are identical, the request remained intact during transmission.]],
   homepage = "https://github.com/Optum/kong-upstream-jwt",
   license = "Apache 2.0"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins.kong-upstream-jwt.access"] = "src/access.lua",
      ["kong.plugins.kong-upstream-jwt.handler"]  = "src/handler.lua",
      ["kong.plugins.kong-upstream-jwt.schema"]= "src/schema.lua"
   }
}
