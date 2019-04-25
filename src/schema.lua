-- © Optum 2018

return {
  fields = {
    issuer = { type = "string", required = true },
    audience = { type = "string", required = true },
    private_key_location = { type = "string", required = true },
    public_key_location = { type = "string", required = true }
  }
}
