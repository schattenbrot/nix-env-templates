# Nix Env Flakes

Trying to get flakes working with direnv.

## How to use it?

> use flake "github:schattenbrot/nix-env-templates?dir=**{package}/{version}**

`Package` is the package with a specific `Version`. Omitting the `Version` should result in latest ... possibly...

### When using direnv

Add something like this in `.envrc`:

```bash
use flake "github:schattenbrot/nix-env-templates?dir=go"
use flake "github:schattenbrot/nix-env-templates?dir=node"

for dir in $(find . -maxdepth 1 -type d -not -path '.'); do
	cd $dir
	layout node
	cd ..
done
```

## Supported Packages and Versions

### Node

| Package | Version | nix-package |
| ------- | ------- | ----------- |
| node    |         | nodejs_24   |
| node    | 20      | nodejs_20   |
| node    | 22      | nodejs_22   |
| node    | 23      | nodejs_23   |
| node    | 24      | nodejs_24   |

To use node_packages as if they were installed globally you can enable `layout node` in the .envrc file.

### Go

| Package | Version | nix-package |
| ------- | ------- | ----------- |
| go      |         | go_1_24     |
| go      | 1.22    | go_1_22     |
| go      | 1.23    | go_1_23     |
| go      | 1.24    | go_1_24     |
| go      | 1.25    | go_1_25     |

# Android

| Package | Version | nix-packages                  |
| ------- | ------- | ----------------------------- |
| android |         | android-studio, android-tools |
