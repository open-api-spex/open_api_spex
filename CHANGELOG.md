# 3.10.0

Thanks to the contributions of the community ❤️💙💛💜🧡

- [noozo](https://github.com/noozo)
- [sernajoto](https://github.com/sernajoto)
- [pacoguzman](https://github.com/pacoguzman)
- [vitorleal](https://github.com/vitorleal)
- [zlarsen](https://github.com/zlarsen)
- [surik](https://github.com/surik)
- [brentjr](https://github.com/brentjr)
- [dwmcc](https://github.com/dwmcc)
- [wingyplus](https://github.com/wingyplus)

- Feature: Support OAuth2 for swagger-ui (#217)
- Feature: Support `default` response type in responses (#301)
- Feature: Allow overriding `x-struct` in `OpenApiSpex.shcmea/1` (#304)
- Feature: Ability to specify `deprecated` in ControllerSpec operation (#296)
- Feature: `:struct?` and `:derive?` options in `OpenApiSpex.schema/1` (#312)
- Feature: `OpenApiSpex.add_schemas/2` (#314)
- Enhancement: Remove api_spec data from Conn (#286)
- Enhancement: More informative errors for bad schema (#288, #284, #287) 
- Fix: Convert `:format` value to atom when decoding schema file (#293)
- Fix: Type spec in OpenApiSpex.Info
- Fix: Elixir Formatter rules in published package (#306)
- Docs: Fix spelling error in example code (#295)
- Docs: Fix type in README (#297)
- Docs: Fix links and punctuation in README (#298)
- Docs: Promote ControlerSpecs as the preferred API for controller operations (#311)

# 3.9.0

Thanks to the contributions of the community ❤️💙💛💜🧡

- [feng19](https://github.com/feng19)
- [jbernardo95](https://github.com/jbernardo95)

- Feature: Generate example from schema (#266)
- Feature: Allow SwaggerUI to be configured via Plug opts (#271)
- Feature: Warn on invalid or missing operation specs (#273, #278)
- Feature: Experimental alternative API for defining Operation specs (#265, #280)
- Fix: Handle the same operation occurring at different routes (#272)
- Fix: Casting header names that have upper-case letters in specs (#281)
- Maint: Upgrade Elixir dependencies in example projects (#269)
- Maint: Format project with Elixir Formatter (#279)

# 3.8.0

Thanks to the contributions of the community ❤️💙💛💜🧡

- [feng19](https://github.com/feng19)
- [gdiasdasilva](https://github.com/gdiasdasilva)
- [mojidabckuu](https://github.com/mojidabckuu)
- [noozo](https://github.com/noozo)
- [Shikanime](https://github.com/Shikanime)
- [slashdotdash](https://github.com/slashdotdash)
- [velimir](https://github.com/velimir)
- [wardes](https://github.com/wardes)

* Feature: Custom validators (#243)
* Feature: Swagger json generation Mix Task (#249)
* Feature: Customizable cache adapter (#262)
* Enhancement: Allow passsing `false` to `@doc` annotation to skip the warning. (#236)
* Enhancement: Make @doc parameters declaration consistent with open api (#237)
* Enhancement: Support `security` `@doc` string attribute on operations (#251)
* Enhancement: Allow a `Reference` to be used for directly in the `parameters` definition (#258)
* Enhancement: Allow a `Reference` to be used for an Operation's request body (#260)
* Docs: Fixes README.md responses example typo "unprocessible" (#248)
* Docs: Fix security example to use correct types for the keys (#239)
* Fix: Remove default pop value for :type shortcut in `@doc` specs (#238)
* Fix: Nested parameters when served from file based schema (#241)
* Fix: Error handling for oneOf (#246)
* Fix: json:api compatible data shape option for JsonRenderError (#245)
* Fix: ReferenceError: `components.parameter` missing `s` in CastParamters (#257)
* Fix: struct def for custom validators (#263)

# 3.7.0

Thanks to the contributions of the community ❤️💙💛💜🧡

- [soundmonster](https://github.com/soundmonster)
- [slapers](https://github.com/slapers)
- [pedroassumpcao](https://github.com/pedroassumpcao)
- [petersenlance](https://github.com/petersenlance)
- [mdogo](https://github.com/mdogo)
- [minibikini](https://github.com/minibikini)
- [rinpatch](https://github.com/rinpatch)
- [palcalde](https://github.com/palcalde)

* Enhancement: Multiple bug fixes and edge case handling of ExDoc based operation specs
* Enhancement: Upgrade Swagger UI to 3.24.2 (#210)
* Enhancement: Improve oneOf casting (#227)
* Docs: Add SecurityScheme usage and examples in the readme (#215)
* Fix: References for query params and discriminators with mappings not working (#200)
* Fix: Errors in parameter pattern validation (#206)
* Fix example (#212)
* Fix: CastAndValidate: incorrect content-type handling (#218)
* Fix: Can't cast and validate a JSON array as request body (#229)

# 3.6.0

Thanks to the contributions of the community ❤️💙💛💜🧡

- [Zakjholt](https://github.com/Zakjholt)
- [supermaciz](https://github.com/supermaciz)
- [mrmstn](https://github.com/mrmstn)
- [aisrael](https://github.com/aisrael)

* Feature: Improved inspect output of `%Schema{}` (#193)
* Feature: Auto-populate schema title from module name (#192)
* Feature: Derive Operation ID from meta in ExDoc specs (#195)
* Fix: Validation of array minItems ignores empty array (#179)
* Fix: Add minimum/maximum validation for number properties (#181)
* Fix: Properly validate header params (#184)
* Fix: Support free-form query parameters (#171)
* Fix: Resolve schema modules from Response in Components (#186)

# 3.5.2

Thanks to the contributions of the community ❤️💙💛💜🧡

- [jung-hunsoo](https://github.com/jung-hunsoo)
- [linnal](https://github.com/linnal)

* Fix: Update README for Info from `Application.spec/2` (#174)
* Fix: Casting for unsupported params (#170)

# 3.5.1

Thanks to the contributions of the community ❤️💙💛💜🧡

- [mrmstn](https://github.com/mrmstn)

* Fix: Issues with complex types for phoenix endpoints (#161)
* Fix: In ExDoc-based operation spec (experimental), change key name used to define `requestBody` (#164)
* Fix: `oneOf` schema having object schemas (#167)

# 3.5.0

Thanks to the contributions of the community ❤️💙💛💜🧡

- [surik](https://github.com/surik)
- [fmcgeough](https://github.com/fmcgeough)
- [zero778](https://github.com/zero778)
- [vovayartsev](https://github.com/vovayartsev)
- [superhawk610](https://github.com/superhawk610)
- [jung-hunsoo](https://github.com/jung-hunsoo)
- [supermaciz](https://github.com/supermaciz)
- [Geekfish](https://github.com/Geekfish)
- [mrmstn](https://github.com/mrmstn)
- [waltfy](https://github.com/waltfy)
- [ggpasqualino](https://github.com/ggpasqualino)
- [hauleth](https://github.com/hauleth)

* Feature: Ability to import Open API documents instead of defining them in Elixir (#152)
* Feature: Add `display_operation_id` option to SwaggerUI (#138)
* Feature: Schema validation: schema type required when `properties` is present (#146)
* Feature: Improve reporting of test assertion failures (#150)
* Feature: Support for `min_properties` validation for Object properties (#131)
* Feature: Support property defaults in new Cast & Validate API (#145)
* Feature: Support for casting file uploads (#133)
* Feature: Support "\$ref" in operation's parameters (#137)
* Feature: Experimental ExDoc-based endpoint API specifications (#162)
* Deprecation: Deprecate old cast and validation API (#153)
* Deprecation: Set minimum supported Elixir version to 1.7, maximum 1.9 (#130)
* Fix: Prevent example properties with nil values from being stripped out during JSON encoding (#142)
* Fix: casting/validating of oneOf, anyOf (#148)
* Fix: Pass additional properties through when allowed via `additionalProperties` (#155)
* Fix: for `allOf` definitions for multi-typed `allOf` array and complex structs with inheritance (#156)
* Fix: Allow a root-level property of compiled schema to be a schema (#158)
* Docs: Fix bugs and improve wording in README (#126)
* Docs: update phoenix guide and samples (#129)
* Docs: README instructions for separating API operation from controller (#140)

The original cast & validation API has been deprecated and replaced with an API that was introduced in 3.2.0.
Using the old API will now result in compiler and runtime warnings.

Old API:

```elixir
defmodule PhoenixAppWeb.UserController do
  use PhoenixAppWeb, :controller
  plug OpenApiSpex.Plug.Cast
  plug OpenApiSpex.Plug.Validate
end
```

Will result in:

```
warning: OpenApiSpex.Plug.Cast.call/2 is deprecated. Use OpenApiSpex.Plug.CastAndValidate instead
  test/support/user_controller.ex:1

warning: OpenApiSpex.Plug.Validate.call/2 is deprecated. Use OpenApiSpex.Plug.CastAndValidate.call/2 instead
  test/support/user_controller.ex:1
```

New API

```elixir
defmodule PhoenixAppWeb.UserController do
  use PhoenixAppWeb, :controller
  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true
end
```

Note that this changes the default error response. Before, it was a single, plain-text error message.
Now, it's a list of error maps, containing more error information.

Old API:

```elixir
defmodule MyAppWeb.MyControllerTest do
  use MyApp.ConnCase
  # Old module
  import OpenApiSpex.Test.Assertions

  ## The test themselves don't need to change

  test "UserController produces a UsersResponse", %{conn: conn} do
    api_spec = MyApp.ApiSpec.spec()
    json =
      conn
      |> get(user_path(conn, :index))
      |> json_response(200)

    assert_schema(json, "UsersResponse", api_spec)
  end

  test "something" do
    api_spec = MyApp.ApiSpec.spec()
    schema = MyApp.Schemas.UsersResponse.schema()
    assert_schema(schema.example, "UsersResponse", api_spec)
  end
end
```

Will produce:

```
warning: OpenApiSpex.Test.Assertions.assert_schema/3 is deprecated. Use OpenApiSpex.TestAssertions.assert_schema/3 instead
  test/my_controller_test.exs:21
```

New API:

```elixir
defmodule MyAppWeb.MyControllerTest do
  use MyApp.ConnCase
  # New module
  import OpenApiSpex.TestAssertions

  # The test themselves don't need to change,
  # but the new assertion is more discerning,
  # so it may find problems that the old API didn't.
end
```

# 3.4.0

Thanks to the contributions of the community ❤️💙💛💜🧡

- [surik](https://github.com/surik)
- [holsee](https://github.com/holsee)
- [fmcgeough](https://github.com/fmcgeough)

* Feature: the `OpenApiSpex` and `OpenApiSpex.Info` structs now support [extensions](https://swagger.io/docs/specification/openapi-extensions/) (#108) (#114)

The `extensions` key may contain any additional data that should be included in the info, eg the `x-logo` and `x-tagGroups` extensions:

```elixir
 spec = %OpenApi{
   info: %Info{
     title: "Test",
     version: "1.0.0",
     extensions: %{
       "x-logo" => %{
         "url" => "https://example.com/logo.png",
         "backgroundColor" => "#FFFFFF",
         "altText" => "Example logo"
       }
     }
   },
   extensions: %{
     "x-tagGroups" => [
       %{
         "name" => "Methods",
         "tags" => [
           "Search",
           "Fetch",
           "Delete"
         ]
       }
     ]
   },
   paths: %{ ... }
 }
```

- Deprecation: `OpenApiSpex.Server.from_endpoint/2` has been deprecated in favor of `OpenApiSpex.Server.from_endpoint/1`.
  Simply remove the `otp_app:` option from the call to use the new function. (#116)

```elixir
  # server = Server.from_endpoint(Endpoint, otp_app: :my_phoenix_app)
  server = Server.from_endpoint(MyPhoenixAppWeb.Endpoint)
```

- Fix: The internal representation of a Phoenix Route struct changed in Phoenix 1.4.7 breaking the `OpenApiSpex.Paths.from_router/1` function. OpenApiSpex 3.4.0 will support both representations until the Phoenix API becomes stable. (#118)

# 3.3.0

Thanks to the contributions from the community! 👍

- [hauleth](https://github.com/hauleth)
- [cstaud](https://github.com/cstaud)
- [xadhoom](https://github.com/xadhoom)
- [nurugger07](https://github.com/nurugger07)
- [fenollp](https://github.com/fenollp)
- [moxley](https://github.com/moxley)

* Feature: Enums expressed as atoms or atom-keyed maps can be cast from strings (or string-keyed maps). (#60) (#101)

Example:

```elixir
  parameters: [
    Operation.parameter(:sort, :query, :string, "sort direction", enum: [:asc, :desc])
  ],
```

- Fix: Schema module references are resolved in in-line parameter/response schemas. (#77) (#105)

Example: The response schema is given in-line as an array, but items are resolved from the `User` module.

```elixir
  responses: %{
    200 => Operation.response(
      "User array",
      "application/json",
      %Schema{
        type: :array,
        items: MyApp.Schemas.User
      }
    )
  }
```

- Fix: Ensure integer query parameters are validated correctly after conversion from string. (#106)
- Fix: Ensure integers are validated correctly against schema `minimum`, `maximum`, `exlcusiveMinimum` and `exclusiveMaximum` attributes. (#97)
- Fix: Ensure strings are cast to `Date` or `DateTime` types when the schema format is `:date` or `:date-time`. (#90) (#94)
- Docs: The contract for module supplied to the `PutApiSpec` plug is now documented by the `OpenApi` behaviour. (#73) (#103)
- Docs: Poison replaced with Jason in example and tests (#104)
- Docs: Improved documentation for combined `CastAndValidate` plug. (#91)
- Internals: Cache mapping from phoenix controller/action to OpenApi operation. (#102)

# 3.2.1

Patch release for documentation updates and improved error rendering Plug when using `CastAndValidate`.

Thanks [moxley](https://github.com/moxley)!

- Cast and validate guide (#89)

# 3.2.0

This release contains many improvements and internal changes thanks to the contributions of the community!

- [moxley](https://github.com/moxley)
- [kpanic](https://github.com/kpanic)
- [hauleth](https://github.com/hauleth)
- [nurugger07](https://github.com/nurugger07)
- [ggpasqualino](https://github.com/ggpasqualino)
- [teamon](https://github.com/teamon)
- [bryannaegele](https://github.com/bryannaegele)

* Feature: Send Plug CSRF token in x-csrf-token header from Swagger UI (#82)
* Feature: Support `Jason` library for JSON serialization (#75)
* Feature: Combine casting and validation into a single `CastAndValidate` Plug (#69) (#86)
* Feature: Improved performance by avoiding copying of API Spec data in each request (#83)
* Fix: Convert `integers` to `float` when casting to `number` type (#81) (#84)
* Fix: Validate strings without trimming whitespace first (#79)
* Fix: Exclusive Minimum and Exclusive maximum are validated correctly (#68)
* Fix: Report errors when unable to convert to the expected number/string/boolean type (#64)
* Fix: Gracefully report error when failing to convert request params to an object type (#63)
* Internals: Improved code organisation of unit test suite (#62)

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
  - `discriminator` is used to cast polymorphic shemas to a more specific schema.
  - `allOf` will cast all properties in each included schema
  - `oneOf` / `anyOf` will attempt to use each schema until a successful cast is made

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
Eg: "#/user/name: Value does not match pattern: [a-zA-Z][a-za-z0-9_]+"

# 1.0.1

Cache API spec in application environment after first call to PutApiSpec plug

# 1.0.0

Initial release. This package is inspired by [phoenix_swagger](https://github.com/xerions/phoenix_swagger) but targets Open API Spec 3.0.
