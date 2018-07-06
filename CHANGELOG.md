# 2.2.0

- Feature: Support composite schemas in `OpenApiSpex.schema`

structs defined with `OpenApiSpex.schema` will include all properties defined in schemas
listed in `allOf`. See the `OpenApiSpex.Schema` docs for some examples.

- Feature: Support composite and polymorphic schemas with `OpenApiSpex.cast/3`.
   -  `discriminator` is used to cast polymorphic shemas to a more specific schema.
   -  `allOf` will cast all properties in each included schema
   -  `oneOf` / `anyOf` will attempt to use each schema until a successful cast is made

# 2.1.1

- Fix: (#24, #25) Operations that define `parameters` and a `requestBody` schema can be validated.

# 2.1.0

- Feature: (#16) Error response from `OpenApiSpex.cast` when value contains unknown properties and schema declares `additionalProperties: false`.
- Feature: (#20) Update swagger-ui to version 3.17.0.
- Fix: (#17, #21, #22) Update typespecs for struct types.

# 2.0.0

Major version update following from API change in `OpenApiSpex.cast` and `OpenApiSpex.validate`.
When casting/validating all parameters against an `OpenApiSpex.Operation`, the complete `Plug.Conn` struct must now be passed, where the combined params map was previously accepted.
This allows `OpenApiSpex.cast` / `OpenApiSpex.validate` to check that the parameters are being supplied in the expected location (query, path, body, header, cookie).
In version 2.0.0, only unexpected query parameters will cause a 422 response from `OpenApiSpex.Plug.Cast`, this may be extended in future versions to detect more invalid requests.

Thanks [cstaud](https://github.com/cstaud), [rutho](https://github.com/ThomasRueckert), [anagromataf](https://github.com/anagromataf) for contributions!


 - Change: (#9) swagger-ui updated to 3.13.4
 - Change (#9) Unexpected query parameters will produce an error response from `OpenApiSpex.Plug.Cast`
 - Change: (#9) `OpenApiSpex.cast/4` now requires a complete `Plug.Conn` struct when casting all parameters of an `OpenApiSpex.Operation`
 - Change: (#14) `OpenApiSpex.validate/4` now requires a complete `Plug.Conn` struct when validating all parameters of an `OpenApiSpex.Operation`
 - Fix: (#11) Support resolving list of schema modules in `oneOf`, `anyOf`, etc.
 - Fix: `OpenApiSpex.schema` macro allows defining schemas without any properties
 - Fix: type declarations better reflect when `nil` is allowed


# 1.1.4

 - `additionalProperties` is now `nil` by default, was previously `true`

# 1.1.3

 - Fix several bugs and make some minor enhancements to schema casting and validating.
 - Add sample application to enable end-to-end testing

# 1.1.2

Fix openapi version output in generated spec.

# 1.1.1

Update swagger-ui to version 3.3.2

# 1.1.0

Include path to invalid element in validation errors.
Eg: "#/user/name: Value does not match pattern: [a-zA-Z][a-zA-Z0-9_]+"

# 1.0.1

Cache API spec in application environment after first call to PutApiSpec plug

# 1.0.0

Initial release. This package is inspired by [phoenix_swagger](https://github.com/xerions/phoenix_swagger) but targets Open API Spec 3.0.


