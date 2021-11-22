# PlugApp

This simple Plug API Application demonstrates the usage of `open_api_spex`.

 - [api_spec.ex](lib/plug_app/api_spec.ex) contains the outline of the api spec
 - [schemas.ex](lib/plug_app/schemas.ex) contains the request/response schema modules
 - [router.ex](lib/plug_app/router.ex) contains the plug router

 To run this application:

 ```
 mix deps.get
 mix ecto.create
 mix ecto.migrate
 mix run --no-halt
 ```

 Navigate to [http://localhost:4000/swaggerui](http://localhost:4000/swaggerui)
