# eglot-moonbit (WIP)

[![License: GPL3](https://img.shields.io/badge/License-GPL3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

> Moonbit-lsp integration with Eglot

This package provides [Eglot](https://github.com/joaotavora/eglot) integration for the [Moonbit](https://moonbitlang.com/) programming language, enabling Language Server Protocol features in Emacs.

## Features

- LSP support for Moonbit via Eglot
- Code formatting with `moonbit-lsp/format-nth-toplevel`
- Test execution commands:
  - `moonbit-lsp/run-test` - Run tests
  - `moonbit-lsp/update-test` - Update tests
  - `moonbit-lsp/run-all-tests` - Run all tests
  - `moonbit-lsp/update-all-tests` - Update all tests
- Main program execution with `moonbit-lsp/run-main`
- Compilation mode with error regexps for Moonbit output

## Requirements

- Emacs 30.1+
- Eglot 1.17.30+
- [moonbit-lsp](https://github.com/moonbitlang/moonbit) server installed
- [eglot-codelens](https://github.com/zsxh/eglot-codelens)

## Installation

### Using package-vc

```emacs-lisp
(unless (package-installed-p 'eglot-moonbit)
  (package-vc-install
   '(eglot-moonbit :url "https://github.com/zsxh/eglot-moonbit")))
```

### Manual installation

Download `eglot-moonbit.el` and add it to your `load-path`:

```elisp
(add-to-list 'load-path "/path/to/eglot-moonbit")
(require 'eglot-moonbit)
```

## Usage

Add the following to your Emacs configuration to automatically enable Eglot for Moonbit files:

```elisp
(push '(moonbit-mode . (eglot-moonbit-server . ("moonbit-lsp" "--stdio")))
        eglot-server-programs)
```

Then enable `eglot` in moonbit buffers with `M-x eglot`.

## TODO

- [ ] Handle `moonbit-lsp/debug-test` command
- [ ] Handle `moonbit-lsp/trace-test` command
- [ ] Handle `moonbit-lsp/debug-main` command
- [ ] Handle `moonbit-lsp/trace-main` command
- [ ] Handle `moonbit-ai/generate` command
- [ ] Handle `moonbit-ai/generate-batched` command
- [ ] Improve target backend and package name detection for `moonbit-lsp/run-main`

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See [LICENSE](LICENSE) for details.
