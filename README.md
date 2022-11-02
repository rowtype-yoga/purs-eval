# purs-eval
A simple PureScript expression evaluation tool

## Usage

```bash
EXAMPLE=cat <<EOF
module Main where

import Effect.Console (log)

main = log "hello"
EOF

# With npm
echo $EXAMPLE | npx purs-eval

# With nix
echo $EXAMPLE | nix run github:klarkc/purs-eval 

# Piping to node
echo $EXAMPLE | npx purs-eval | nix run nixpkgs#nodejs -- --experimental-network-imports --input-type module
```
