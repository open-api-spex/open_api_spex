# Contributing

## Open an issue

If you've found a bug or would like to discuss a new feature, start by [opening an issue](https://github.com/open-api-spex/open_api_spex/issues/new).
Where possible, please refer to the relevant sections of the Open API Specification 3.0 or JSON Schema Specification:

- https://swagger.io/docs/specification/
- https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md
- https://json-schema.org/understanding-json-schema/

## Send a Pull Request

Link your pull request to the issue opened earlier, eg `fixes #123`.
Please be patient as maintainers are generally volunteering their time to support the project 🙂

## Get Help

You can ask for help using OpenApiSpex by:

- [Opening an issue](https://github.com/open-api-spex/open_api_spex/issues/new) - you may have run in to a bug or poorly documented feature!
- Using the [open_api_spex slack channel](https://elixir-lang.slack.com/messages/CPEN5UW1X)
- Using the [Elixir Forum thread](https://elixirforum.com/t/openapispex-openapi-swagger-3-0-for-plug-apis/15614)

## Releasing (Maintainers Only)

To ship a release to Hex.pm, complete the following checklist:

- Confirm the project builds and all tests pass on your machine `mix clean; mix test`
- If possible, look for regressions by testing `master` against a project that uses `:open_api_spex`.
- Confirm the docs build successfully and do not contain obvious formatting errors `mix docs; open doc/index.html`
- Review the `CHANGELOG.md` file, adding a line for each pr / issue and a larger description for significant changes.
- Update the `@version` attribute in `mix.exs`
- Update the `Installation` section of the `README.md` file with the new version (for minor and major releases)
- Commit and tag the `master` branch with the version and a leading `v`, eg: `v3.14.15`
- Push master branch to `open_api_spex` repo
- Push package to Hex: `mix hex.publish`
- Add a release announcement to the [Elixir Forum thread](https://elixirforum.com/t/openapispex-openapi-swagger-3-0-for-plug-apis/15614)
- Add a release announcement to the #open_api_spex channel in the Elixir Slack workspace
