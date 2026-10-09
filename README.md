# AUTOTALYS

AUTOTALYS is a software system for automated production and processing of nuclear data with TALYS and related codes.
Applications include:

- Automated production of nuclear data libraries (TENDL files)
- Automated optimization to experimental data from EXFOR
- Reaction rate libraries for astrophysics
- Sensitivity profiles for TALYS
- Covariance matrices

This repository only contains the setup scripts needed to obtain the complete AUTOTALYS source tree.

Two installation methods are provided:

- `clone_autotalys.bash` — recommended for users with Git
- `download_autotalys.bash` — alternative for users without Git

Both scripts create an `autotalys/` directory containing all required source packages.

## Included software

The AUTOTALYS system currently includes:

### TALYS-related codes

- TALYS
- TEFAL
- TASMAN
- ENDFTABLES
- AUTONORM
- AUTOENDF
- AUTOTALYS_TOOLS

### External software

- NJOY2016
- PREPRO
- ENDF Utility Codes
- FUDGE

The individual packages are obtained directly from their respective GitHub repositories.

## Installation with Git

This is the recommended method. First clone this small setup repository:

```bash
git clone https://github.com/arjankoning1/autotalys.git autotalys_setup
cd autotalys_setup

bash clone_autotalys.bash "$HOME/autotalys"

cd "$HOME/autotalys"
bash install_autotalys.bash
```

The name `autotalys_setup` distinguishes the repository containing the download scripts from the complete AUTOTALYS source tree created at `$HOME/autotalys`. The destination must not already exist; the clone script refuses to overwrite an existing installation.

The main installation script is obtained automatically from the `autotalys_tools` repository.

To use another installation directory, pass its path to the clone script:

```bash
bash clone_autotalys.bash /path/to/autotalys
cd /path/to/autotalys
bash install_autotalys.bash
```

Without an argument, `clone_autotalys.bash` creates `autotalys/` in the current working directory.

The Git installation keeps the `.git` directories of all packages, which makes it possible to inspect changes and update individual repositories later with normal Git commands.

### Download only the clone script

Users with Git can alternatively obtain the setup script directly:

```bash
curl -fL \
  https://raw.githubusercontent.com/arjankoning1/autotalys/main/clone_autotalys.bash \
  -o clone_autotalys.bash

bash clone_autotalys.bash "$HOME/autotalys"

cd "$HOME/autotalys"
bash install_autotalys.bash
```

## Installation without Git

Download and run the archive-based setup script:

```bash
curl -fL \
  https://raw.githubusercontent.com/arjankoning1/autotalys/main/download_autotalys.bash \
  -o download_autotalys.bash

bash download_autotalys.bash

cd "$HOME/autotalys"
bash install_autotalys.bash
```

This uses `curl` to download source archives directly from GitHub and creates the AUTOTALYS source tree at `$HOME/autotalys`. The destination must not already exist.

The downloaded source trees do not contain `.git` directories. They therefore cannot be updated with `git pull`.

To obtain a newer version, preserve any local work and download a fresh source tree after moving the existing installation out of the way.

The download script also performs the small adjustment required to install FUDGE from a GitHub source archive, since FUDGE normally determines its version from Git metadata.

## Directory structure

After cloning or downloading, the structure is approximately:

```text
autotalys/
├── talys/
├── tefal/
├── tasman/
├── endftables/
├── autonorm/
├── autoendf/
├── autotalys_tools/
├── NJOY2016/
├── PREPRO/
├── ENDF-utility-codes/
├── fudge/
└── install_autotalys.bash
```

After installation, executables used by AUTOTALYS are collected through the common:

```text
autotalys/bin/
```

directory.

## Requirements

The setup scripts require a Unix-like environment such as:

- macOS
- Linux

For the Git installation, `git` is required.

For the download installation, `curl` and `tar` are required.

The complete AUTOTALYS installation also requires the compilers and build tools needed by the individual packages, including Fortran, C/C++, CMake, Make and Python.

FUDGE is installed in a Python virtual environment. The current AUTOTALYS installation uses Python 3.11.

## Test the installation

To test a successful installation, run the following sample case for niobium-93:

```bash
~/path/to/autotalys/bin/autotalys -element Nb -mass 93 -covar -ntalys 2 -E30
```

Replace `/path/to/autotalys` with the actual directory where AUTOTALYS was installed. For example, if AUTOTALYS was installed in your home directory, use:

```bash
~/autotalys/bin/autotalys -element Nb -mass 93 -covar -ntalys 2 -E30
```

The calculation can be launched from any working directory. Verify that it completes without errors and produces the expected output files.

## Recommended method

For development and regular use, cloning the small `autotalys_setup` repository and following the Git installation instructions above is recommended.

It preserves the complete repository information and makes later updates and code development straightforward.

The download method is intended primarily for users who want to install AUTOTALYS on a system where Git is unavailable.

## Updating

With the Git installation, individual packages can be updated from inside their directories, for example:

```bash
cd "$HOME/autotalys/talys"
git pull
```

To update the setup scripts themselves, run `git pull` inside `autotalys_setup`.

After updating packages, rerun the relevant installation script if recompilation is required.

For the non-Git installation, the simplest update procedure is to download a fresh AUTOTALYS source tree.

## Repository purpose

This repository intentionally remains small.

It contains only:

```text
clone_autotalys.bash
download_autotalys.bash
README.md
```

The actual AUTOTALYS software is maintained in the individual repositories listed above.

## Author

Arjan Koning
