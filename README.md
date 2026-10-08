# AUTOTALYS

AUTOTALYS is a software system for automated production and processing of nuclear data with TALYS and related codes.
Applications include:

- Automated production of nuclear data libraries (TENDL files)
- Automated optimization to experimental data from EXFOR
- Reaction rate libraries for astrophysics
- Sensitivity profiles for TALYS
- Covariance matrices

This repository only contains the bootstrap scripts needed to obtain the complete AUTOTALYS source tree.

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

This is the recommended method.

Download `clone_autotalys.bash`, make it executable, and run it from the directory in which you want the AUTOTALYS directory to be created:

```bash
chmod +x clone_autotalys.bash
./clone_autotalys.bash
```

By default this creates:

```text
./autotalys/
```

For example:

```bash
cd $HOME
./clone_autotalys.bash
```

creates:

```text
$HOME/autotalys/
```

If an explicit destination is supported by the script, it can also be given as an argument:

```bash
./clone_autotalys.bash /path/to/autotalys
```

The Git installation keeps the `.git` directories of all packages, which makes it possible to inspect changes and update individual repositories later with normal Git commands.

After cloning is complete:

```bash
cd autotalys
chmod +x install_autotalys.bash
./install_autotalys.bash
```

The main installation script is obtained automatically from the `autotalys_tools` repository.

## Installation without Git

For systems without Git, use:

```bash
chmod +x download_autotalys.bash
./download_autotalys.bash
```

This uses `curl` to download source archives directly from GitHub and creates the same AUTOTALYS source-tree layout.

After downloading:

```bash
cd autotalys
chmod +x install_autotalys.bash
./install_autotalys.bash
```

The downloaded source trees do not contain `.git` directories. They therefore cannot be updated with `git pull`.

To obtain a newer version, remove the existing AUTOTALYS source tree and run `download_autotalys.bash` again.

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

The bootstrap scripts require a Unix-like environment such as:

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

For development and regular use, the Git installation is recommended:

```bash
./clone_autotalys.bash
```

It preserves the complete repository information and makes later updates and code development straightforward.

The download method is intended primarily for users who want to install AUTOTALYS on a system where Git is unavailable.

## Updating

With the Git installation, individual packages can be updated from inside their directories, for example:

```bash
cd autotalys/talys
git pull
```

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
