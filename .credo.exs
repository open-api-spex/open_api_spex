%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/"],
        excluded: []
      },
      plugins: [],
      requires: [],
      strict: false,
      parse_timeout: 5000,
      color: true,
      checks: [
        {Credo.Check.Consistency.ParameterPatternMatching, false}
      ]
    }
  ]
}
