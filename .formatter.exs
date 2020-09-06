[
  inputs: ["{mix,.formatter}.exs", "{config,lib,rel,test}/**/*.{ex,exs}"],
  import_deps: [:plug, :phoenix],
  locals_without_parens: [
    transport: 2,
    action_fallback: 1,
    socket: 2,
    render: 2,
    operation: 2,
    tags: 1,
    security: 1
  ],
  export: [
    locals_without_parens: [
      operation: 2,
      tags: 1,
      security: 1
    ]
  ]
]
