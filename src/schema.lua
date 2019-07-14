-- © Optum 2018

return {
  fields = {
    issuer = { type = "string", required = false },
    private_key_location = { type = "string", required = false },
    public_key_location = { type = "string", required = false },
    key_id = { type = "string", required = false},
    header = { type = "string", default = "JWT"},
    include_credential_type = { type = "boolean", default = false}
  }
}
