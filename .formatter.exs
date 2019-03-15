[
  inputs: ["{mix,.formatter}.exs", "{config,lib,rel,test,examples}/**/*.{ex,exs}"],
  import_deps: [:plug, :phoenix],
  locals_without_parens: [
    transport: 2,
    action_fallback: 1,
    socket: 2,
    render: 2
  ]
]
