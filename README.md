# purs-eval
A simple PureScript expression evaluation tool

## Usage

```bash
EXAMPLE="module Main where\nimport Effect.Console (log)\nmain = log \"hello from PS\""

# With npm
echo -e $EXAMPLE | npx purs-eval

# With nix
echo -e $EXAMPLE | nix run github:rowtype-yoga/purs-eval 

# Pipe node (>v18)
echo -e $EXAMPLE | nix run github:rowtype-yoga/purs-eval | nix run nixpkgs#nodejs -- --experimental-network-imports --input-type module

# or with npx
echo -e $EXAMPLE | npx purs-eval | node --experimental-network-imports --input-type module
```
