# 📡 Gleam UI router library

🚧 **Work in progress** not production ready.

[Gleam](https://gleam.run/) UI router to SPA by @gleam-br.

👽 Make SPA router easy and preasure in your life.

[![Package Version](https://img.shields.io/hexpm/v/gbr_ui_router)](https://hex.pm/packages/gbr_ui_router)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gbr_ui_router/)

```sh
gleam add gbr_ui_router@1
```

```gleam
import gbr/ui/router

pub fn main() -> Nil {
  router.try()
}
```

Further documentation can be found at <https://hexdocs.pm/gbr_ui_router>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Build

```sh
gleam clean
gleam build
```

Bun make:

```sh
bunx bunup
```

## Roadmap

- [ ] Pure gleam code here
  - [ ] Using gbr_js library
