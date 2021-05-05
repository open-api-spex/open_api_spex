# Roadmap

## Version 4

- Remove need for `json_render_error_v2: true` option for `CastAndValidate`
- Remove `OpenApiSpex.Plug.Cast`, and rename `Cast2` to `Cast`.
- Simplify interface for error rendering modules
- Pass casted request params to `conn` without breaking contract with `Conn.t`
- Remove `@derive` call in `OpenApiSpex.schema/1`
