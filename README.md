# purs-eval
A simple PureScript expression evaluation tool

## Usage

```bash

# With npm
echo -e "module Main where\nimport Effect.Console (log)\nmain = log \"hello\"" | npx purs-eval

# With nix
echo -e "module Main where\nimport Effect.Console (log)\nmain = log \"hello\"" | nix run github:klarkc/purs-eval
```
