#!/usr/bin/env bash

# October 6, 2026
# Arjan Koning

set -euo pipefail

AUTOTALYS_DIR="${1:-$PWD/autotalys}"

if [[ -e "$AUTOTALYS_DIR" ]]; then
    echo "ERROR: $AUTOTALYS_DIR already exists."
    echo "Remove it first if you want a completely new installation."
    exit 1
fi

mkdir "$AUTOTALYS_DIR"
cd "$AUTOTALYS_DIR"

echo "Cloning the entire Autotalys system"
echo

clone()
{
    local repo=$1
    local url=$2

    echo "***** Cloning $repo"
    git clone "$url" "$repo"
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
    clone "$code" "https://github.com/arjankoning1/${code}.git"
done

#
# Other codes
#
clone NJOY2016 \
    "https://github.com/njoy/NJOY2016.git"

clone PREPRO \
    "https://github.com/IAEA-NDS/PREPRO.git"

clone ENDF-utility-codes \
    "https://github.com/IAEA-NDS/ENDF-utility-codes.git"

clone fudge \
    "https://github.com/LLNL/fudge.git"

#
# Put the main installation script at the top level
#
cp autotalys_tools/bin/install_autotalys.bash .

echo
echo "Autotalys source tree created."
echo
echo "Now run:"
echo "    cd $AUTOTALYS_DIR"
echo "    chmod +x install_autotalys.bash"
echo "    ./install_autotalys.bash"
