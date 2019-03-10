# 3.2.0

This release contains many improvements and internal changes thanks to the contributions of the community!

* [moxley](https://github.com/moxley)
* [kpanic](https://github.com/kpanic)
* [hauleth](https://github.com/hauleth)
* [nurugger07](https://github.com/nurugger07)
* [ggpasqualino](https://github.com/ggpasqualino)
* [teamon](https://github.com/teamon)
* [bryannaegele](https://github.com/bryannaegele)

 - Feature: Send Plug CSRF token in x-csrf-token header from Swagger UI (#82)
 - Feature: Support `Jason` library for JSON serialization (#75)
 - Feature: Combine casting and validation into a single `CastAndValidate` Plug (#69) (#86)
 - Feature: Improved performance by avoiding copying of API Spec data in each request (#83)
 - Fix: Convert `integers` to `float` when casting to `number` type (#81) (#84)
 - Fix: Validate strings without trimming whitespace first (#79)
 - Fix: Exclusive Minimum and Exclusive maximum are validated correctly (#68)
 - Fix: Report errors when unable to convert to the expected number/string/boolean type (#64)
 - Fix: Gracefully report error when failing to convert request params to an object type (#63)
 - Internals: Improved code organisation of unit test suite (#62)

# 3.1.0

 - Add support for validating polymorphic schemas using `oneOf`, `anyOf`, `allOf`, `not` constructs.
 - Updated example apps to work with new API
 - CI has moved from travis-ci.org to travis-ci.com and now uses github apps integration.

 Thanks to [fenollp](https://github.com/fenollp) and [tapickell](https://github.com/tapickell) for contributions!

# 3.0.0

Major version bump as the behaviour of `OpenApiSpex.Plug.Cast` has changed (#39).
To enable requests that contain a body as well as path or query params, the result of casting the
request body is now placed in the `Conn.body_params` field, instead of the combined `Conn.params` field.

This requires changing code such as Phoenix controller actions to from

```elixir
def create(conn, %UserRequest{user: %User{name: name, email: email}}) do
```

to

```elixir
  def create(conn = %{body_params: %UserRequest{user: %User{name: name, email: email}}}, params) do
```

- Feature: A custom plug may be provided to render errors (#46)
- Fix compiler warnings and improve CI process (#53)
- Fix: Support casting GET requests without Content-Type header (#50, #49)
- Open API Spex has been moved to the new `open-api-spex` Github organisation

# 2.3.1

- Docs: Update example application to include swagger generate mix task (#41)
- Fix: Ignore charset in content-type header when looking up schema by content type. (#45)

Thanks to [dmt](https://github.com/dmt) and [fenollp](https://github.com/fenollp) for contributions!

# 2.3.0

- Feature: Validate string enum types. (#33)
- Feature: Detect and report missing API spec in `OpenApiSpex.Plug.Cast` (#37)
- Fix: Correct atom for parameter `style` field typespec (#36)

Thanks to [slavo2](https://github.com/slavo2) and [anagromataf](https://github.com/anagromataf) for
contributions!

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


