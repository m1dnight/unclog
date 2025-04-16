# Unclog

Unclog helps you create and manage complex changelog files by separating them into files.

For each change you make, or topic you work on, you can create a scaffolding directory to put in the changes.
Based on these files, a single `CHANGELOG.md` file is generated.

This project is inspired by [unclog](https://crates.io/crates/unclog) for Rust.

## Getting Started

To create the initial scaffolding for your project, initialize a directory tree.

```shell
mix unclog --init
```

This will create the following directory structure in your project root folder.

```text
.changelogs
└── preamble.md
```

To create your first changelog entry, create the boilerplate scaffolding.

```shell
mix unclog --create first_release
```

This will create the following directory structure in your project root folder.

```
.changelogs
├── release_name_here
│   ├── breaking_changes
│   │   └── change.md
│   ├── bug-fixes
│   │   └── change.md
│   ├── features
│   │   └── change.md
│   └── summary.md
└── preamble.md
```

When you are done editing the changelogs, generate the final `CHANGELOG.md` file.

```shell
mix unclog --generate
```

This will generate (or overwrite) the `CHANGELOG.md` file.

## Example

You can look at the `.changelogs` directory in this project, and the generated `CHANGELOG.md` file.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `unclog` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:unclog, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/unclog>.
