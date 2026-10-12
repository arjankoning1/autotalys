#!/usr/bin/env bash
set -euo pipefail

base="https://nds.iaea.org/talys/libraries.t6"
mkdir -p "$HOME/libraries"
cd "$HOME/libraries"

for part in n-A-D n-E-J n-K-O n-P-S n-T-Z p d t h a g; do
    archive="libraries-${part}.tar"

    curl -fL --retry 3 -C - "$base/$archive" -o "$archive"
    tar -xzf "$archive" --strip-components=1
    rm "$archive"
done
