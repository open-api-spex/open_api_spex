[
  inputs: [
    "{lib,unicode,test}/**/*.{ex,exs}",
    "lib/*/mix.exs"
  ],
  locals_without_parens: [
    transport: 2,
    action_fallback: 1,
    socket: 2,
    render: 2,
    create: 1,

    # Plug
    plug: 1,
    plug: 2,
    forward: 3,

    # Formatter tests
    assert_format: 2,
    assert_format: 3,
    assert_same: 1,
    assert_same: 2,

    # Errors tests
    assert_eval_raise: 3,

    # Mix tests
    in_fixture: 2,
    in_tmp: 2,

    # Phoenix.
    pipe_through: 1,
    head: 3,
    get: 3,
    post: 3,
    patch: 3,
    delete: 3,
    resources: 3
  ]
]
