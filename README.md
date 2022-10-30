# purs-eval
A simple PureScript expression evaluation tool

## Usage

### With npm

```bash
echo "1+1" | npx purs-eval | node
```

### With nix

```bash
echo "1+1" | nix run github:klarkc/purs-eval | nix run nixpkgs#nodejs
```
