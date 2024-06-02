#! /usr/bin/env nix-shell
#! nix-shell -i bash -p node2nix

node2nix -18 -i package.json -o node-packages.nix -c node-composition.nix -e ../../../development/node-packages/node-env.nix
sed -i 's|<nixpkgs>|../../..|' node-composition.nix
