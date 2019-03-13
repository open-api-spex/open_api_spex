[
  inputs: ["{mix,.formatter}.exs", "{config,lib,rel,test}/**/*.{ex,exs}"],
  import_deps: [:plug],
  locals_without_parens: [
    transport: 2,
    action_fallback: 1,
    socket: 2,
    render: 2,

    # Distillery
    set: 1,

    # Phoenix.
    pipe_through: 1,
    head: 3,
    get: 3,
    post: 3
  ]
]
