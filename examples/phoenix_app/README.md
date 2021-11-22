# PhoenixApp

This simple Phoenix API Application demonstrates the usage of `open_api_spex`.

- [api_spec.ex](lib/phoenix_app_web/api_spec.ex) contains the outline of the api spec
- [schemas.ex](lib/phoenix_app_web/schemas.ex) contains the request/response schema modules
- [router.ex](lib/phoenix_app_web/router.ex) contains the plug router


To run this application:

```
mix deps.get
mix phoenix_app_web.open_api_spec
mix ecto.create
mix ecto.migrate
mix phx.server
```

Navigate to [http://localhost:4000/swaggerui](http://localhost:4000/swaggerui)
