# purs-eval
A simple PureScript expression evaluation tool

## Usage

```bash
EXAMPLE="module Main where\nimport Effect.Console (log)\nmain = log \"hello from PS\""

# With npm
echo -e $EXAMPLE | npx purs-eval

# With nix
echo -e $EXAMPLE | nix run github:klarkc/purs-eval 

# Pipe node (>v18)
echo -e $EXAMPLE | nix run github:klarkc/purs-eval | nix run nixpkgs#nodejs -- --experimental-network-imports --input-type module
```
