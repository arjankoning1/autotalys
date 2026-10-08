#!/usr/bin/env bash

# October 7, 2026
# Arjan Koning
#
# Download the complete Autotalys source tree without git.

set -euo pipefail

AUTOTALYS_DIR="$HOME/autotalys"

if [[ -e "$AUTOTALYS_DIR" ]]; then
    echo "ERROR: $AUTOTALYS_DIR already exists."
    echo "Remove it first if you want a completely new installation."
    exit 1
fi

mkdir "$AUTOTALYS_DIR"
cd "$AUTOTALYS_DIR"

echo "Downloading the entire Autotalys system"
echo

download()
{
    local owner=$1
    local repo=$2
    local branch=$3

    local archive="${repo}.tar.gz"
    local url="https://github.com/${owner}/${repo}/archive/refs/heads/${branch}.tar.gz"

    echo "***** Downloading $repo"

    curl -fL "$url" -o "$archive"

    mkdir "$repo"

    tar -xzf "$archive" \
        --strip-components=1 \
        -C "$repo"

    rm "$archive"

    echo
}

#
# My codes
#
for code in \
    talys \
    tefal \
    tasman \
    endftables \
    autonorm \
    autoendf \
    autotalys_tools \
    resbase \
    nubarbase \
    fnsbase 
do
    download arjankoning1 "$code" main
done

#
# Other codes
#
download njoy NJOY2016 main

download IAEA-NDS PREPRO master

download IAEA-NDS ENDF-utility-codes master

download LLNL fudge master

#
# FUDGE normally determines its version from git metadata.
# GitHub source archives contain no .git directory, so provide
# a fallback version for versioningit.
#
echo "***** Preparing FUDGE for archive-based installation"

cd "$AUTOTALYS_DIR/fudge"

if [[ ! -d .git ]]; then

    if ! grep -q '^\[tool.versioningit\]' pyproject.toml; then
        sed -i.bak \
            '/^\[tool.versioningit.tag2version\]/i\
[tool.versioningit]\
default-version = "0+autotalys"\
' pyproject.toml

        rm -f pyproject.toml.bak
    fi

fi

cd "$AUTOTALYS_DIR"

#
# Put the main installation script at the top level
#
cp autotalys_tools/bin/install_autotalys.bash .
chmod +x install_autotalys.bash

echo
echo "Autotalys source tree created."
echo
echo "Now run:"
echo "    cd $AUTOTALYS_DIR"
echo "    ./install_autotalys.bash"
