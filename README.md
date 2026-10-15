# AUTOTALYS

AUTOTALYS is a collection of nuclear-reaction and nuclear-data tools for running TALYS calculations, producing evaluated nuclear data libraries, fitting nuclear-reaction data, and generating sensitivity and covariance results. It combines TALYS, TEFAL, TASMAN and supporting programs in one installation while retaining their individual source repositories.

The small **[AUTOTALYS setup repository](https://github.com/arjankoning1/autotalys)** contains the scripts that assemble the system; the scientific codes and databases are maintained separately.

## Contents of this repository

| File | Purpose |
| --- | --- |
| `clone_autotalys.bash` | Clone the complete system from GitHub, retaining Git histories |
| `download_autotalys.bash` | Download GitHub source archives without requiring Git |
| `download_libraries.bash` | Optionally download the large evaluated nuclear-data collection from the IAEA |
| `README.md` | Installation and usage instructions |

**The large `libraries/` collection is not required for a basic AUTOTALYS installation.** It is only needed for features that use additional external evaluated nuclear-data libraries. See [Optional evaluated libraries](#optional-evaluated-libraries).

## Software and databases

The setup scripts obtain the following packages:

| Category | Repositories | Purpose |
| --- | --- | --- |
| Core codes | [TALYS](https://github.com/arjankoning1/talys), [TEFAL](https://github.com/arjankoning1/tefal), [TASMAN](https://github.com/arjankoning1/tasman) | Reaction calculations, ENDF-6 evaluation production, optimization and covariance calculations |
| Supporting codes | [ENDFTABLES](https://github.com/arjankoning1/endftables), [AUTONORM](https://github.com/arjankoning1/autonorm), [AUTOENDF](https://github.com/arjankoning1/autoendf), [AUTOTALYS_TOOLS](https://github.com/arjankoning1/autotalys_tools) | Data conversion, normalization, processing, plotting and automation |
| Experimental data | [EXFORTABLES](https://github.com/arjankoning1/exfortables) | Experimental data organized by projectile and target |
| Specialized databases | [RESBASE](https://github.com/arjankoning1/resbase), [NUBARBASE](https://github.com/arjankoning1/nubarbase), [FNSBASE](https://github.com/arjankoning1/fnsbase) | Resonance, neutron-multiplicity and fission neutron-spectrum input data |
| Selected integral data | [RESONANCETABLES](https://github.com/arjankoning1/resonancetables) | Selected thermal cross sections, resonance integrals, MACS and average resonance parameters |
| External processing/checking tools | [NJOY2016](https://github.com/njoy/NJOY2016), [PREPRO](https://github.com/IAEA-NDS/PREPRO), [ENDF Utility Codes](https://github.com/IAEA-NDS/ENDF-utility-codes), [FUDGE](https://github.com/LLNL/fudge) | Processing, checking and translating evaluated nuclear data |

The setup obtains only the `n/`, `p/`, `g/`, `d/`, `a/`, `t/`, `h/` and `FY/` directories of EXFORTABLES, rather than cloning the complete repository contents. This is sufficient for using the distributed experimental tables, but **not** for rebuilding the EXFORTABLES database from its original reconstruction inputs.

RESONANCETABLES is downloaded with its existing selected data tables. Reconstructing those tables from primary sources is a separate operation and may require additional databases; it is not part of the standard AUTOTALYS installation.

## Requirements

- macOS or Linux with a Bash shell.
- Git for the recommended clone method; alternatively, `curl` and `tar` for archive downloads.
- A Fortran compiler (for example, `gfortran`), C/C++ compilers, GNU Make and CMake for building the included codes.
- The external programs needed by enabled processing or plotting options, such as Gnuplot and Ghostscript where appropriate.
- Python 3.11 for the current FUDGE installation procedure. The installer first checks for `pyenv` Python 3.11.15 and then for a working `python3.11` executable. FUDGE is installed in `fudge/.venv`.

FUDGE installation is allowed to fail without terminating the overall installation. If it is unavailable, use `-nofudge` for AUTOTALYS runs that would otherwise attempt FUDGE checking. Other mandatory components may still cause installation to stop if their prerequisites are missing.

## Installation using Git (recommended)

Clone this small setup repository and run the assembly script:

```bash
git clone https://github.com/arjankoning1/autotalys.git autotalys_setup
cd autotalys_setup

bash clone_autotalys.bash "$HOME/autotalys"

cd "$HOME/autotalys"
./install_autotalys.bash
```

The destination **must not already exist**; the script deliberately refuses to overwrite an existing installation. The `autotalys_setup/` repository is separate from the assembled `autotalys/` directory.

To install elsewhere, supply an absolute destination path:

```bash
bash clone_autotalys.bash /path/to/autotalys
cd /path/to/autotalys
./install_autotalys.bash
```

Without a destination argument, `clone_autotalys.bash` creates `autotalys/` **inside the current working directory**. With Git, each component keeps its own `.git` directory so packages can subsequently be updated individually.

You can also download only the clone script without cloning the setup repository:

```bash
curl -fL \
  https://raw.githubusercontent.com/arjankoning1/autotalys/main/clone_autotalys.bash \
  -o clone_autotalys.bash
bash clone_autotalys.bash "$HOME/autotalys"
```

## Installation without Git

The archive-based setup script creates the assembled installation at `$HOME/autotalys`:

```bash
curl -fL \
  https://raw.githubusercontent.com/arjankoning1/autotalys/main/download_autotalys.bash \
  -o download_autotalys.bash

bash -n download_autotalys.bash
bash download_autotalys.bash

cd "$HOME/autotalys"
./install_autotalys.bash
```

As with the Git method, the destination must not exist beforehand. GitHub source archives do not include `.git` directories, so updating them requires downloading newer archives rather than using `git pull`.

The download script makes an adjustment to FUDGE's version metadata so that installation from a GitHub source archive is possible without a Git checkout.

## Resulting directory structure

A typical assembled installation looks like:

```text
$HOME/
├── autotalys_setup/             # Only the setup scripts, when cloned with Git
├── autotalys/
│   ├── bin/                    # Common executable entry points after installation
│   ├── talys/
│   │   └── structure/
│   │       └── best/
│   ├── tefal/
│   ├── tasman/
│   ├── endftables/
│   ├── autonorm/
│   ├── autoendf/
│   ├── autotalys_tools/
│   ├── exfortables/
│   ├── resonancetables/
│   ├── resbase/
│   ├── nubarbase/
│   ├── fnsbase/
│   ├── NJOY2016/
│   ├── PREPRO/
│   ├── ENDF-utility-codes/
│   ├── fudge/
│   └── install_autotalys.bash
└── libraries/                  # Optional; downloaded separately
```

The main installer builds the local packages and creates common entry points in `autotalys/bin/`. The paths in this example assume installation in the home directory, but the Git assembly script accepts other destinations.

## Optional evaluated libraries

The **full evaluated nuclear-data collection** is deliberately separate from `exfortables/`, `resbase/` and `resonancetables/`. It provides additional evaluated cross sections and other tables for external-library comparisons, normalization and certain specialized adoption operations.

**Recommended location:** `$HOME/libraries/`, outside the AUTOTALYS installation. This permits sharing the large collection among multiple installations and avoids redownloading it when the source tree is replaced.

From the setup repository, download it with:

```bash
cd "$HOME/autotalys_setup"
bash download_libraries.bash "$HOME/libraries"
```

Or download the script directly and run it:

```bash
curl -fL \
  https://raw.githubusercontent.com/arjankoning1/autotalys/main/download_libraries.bash \
  -o download_libraries.bash
bash download_libraries.bash "$HOME/libraries"
```

The script downloads separate archives for the neutron (`n-A-D`, `n-E-J`, `n-K-O`, `n-P-S`, `n-T-Z`), proton (`p`), deuteron (`d`), triton (`t`), helium-3 (`h`), alpha (`a`) and photon (`g`) data. Allow sufficient disk space for the archives and extracted data.

An alternative destination is supported:

```bash
bash download_libraries.bash "/Volumes/Data/libraries"
```

For that alternative location, export the same path before launching AUTOTALYS:

```bash
export LIBRARIES_DIR="/Volumes/Data/libraries"
```

The standard AUTOTALYS driver currently defaults to `$HOME/libraries` when `LIBRARIES_DIR` is not set. **No symbolic link to `autotalys/libraries` is needed**, and the directory need not exist for calculations that do not use external evaluations.

Some specialized operations require particular evaluation files, not merely the existence of the `libraries/` directory. If an operation requests an unavailable file, provide that file or disable the corresponding operation.

## Environment variables

When you run **`<installation>/bin/autotalys`**, the driver determines `AUTOTALYS_HOME` from its installation directory and exports paths for its subprocesses. You normally do **not** need to add these variables to `.zshrc` or `.bashrc`.

| Variable | Default inside AUTOTALYS | Used for |
| --- | --- | --- |
| `AUTOTALYS_HOME` | Detected installation root | Overall source tree |
| `TALYS_DIR` | `$AUTOTALYS_HOME/talys` | TALYS structure files |
| `TEFAL_DIR` | `$AUTOTALYS_HOME/tefal` | TEFAL data and executables |
| `TASMAN_DIR` | `$AUTOTALYS_HOME/tasman` | TASMAN data and settings |
| `AUTONORM_DIR` | `$AUTOTALYS_HOME/autonorm` | AUTONORM installation |
| `AUTOENDF_DIR` | `$AUTOTALYS_HOME/autoendf` | AUTOENDF tools |
| `AUTOTALYS_TOOLS_DIR` | `$AUTOTALYS_HOME/autotalys_tools` | Utility scripts and programs |
| `EXFORTABLES_DIR` | `$AUTOTALYS_HOME/exfortables` | Experimental data |
| `RESONANCETABLES_DIR` | `$AUTOTALYS_HOME/resonancetables` | Thermal, resonance and MACS tables |
| `BEST_DIR` | `$TALYS_DIR/structure/best` | Selected evaluated cross-section tables |
| `LIBRARIES_DIR` | `$HOME/libraries` | Optional full evaluated-library collection |
| `FUDGE_DIR` | `$AUTOTALYS_HOME/fudge` | FUDGE and its virtual environment |
| `NJOY_DIR`, `PREPRO_DIR`, `BNL_DIR` | Corresponding subdirectories | External processing/checking programs |

`LIBRARIES_DIR` and `EXFORTABLES_DIR` can be overridden by pre-exporting them before starting AUTOTALYS. Other paths are set explicitly by the current driver according to its own installation root.

**Standalone utility programs:** If you execute TALYS, TASMAN, AUTONORM, `driplist`, `naturaltables`, `interCE` or `psycheCE` outside the main AUTOTALYS driver, export whichever directory variables those programs need. For example:

```bash
export AUTOTALYS_HOME="$HOME/autotalys"
export TALYS_DIR="$AUTOTALYS_HOME/talys"
export EXFORTABLES_DIR="$AUTOTALYS_HOME/exfortables"
export RESONANCETABLES_DIR="$AUTOTALYS_HOME/resonancetables"
export BEST_DIR="$TALYS_DIR/structure/best"
export LIBRARIES_DIR="$HOME/libraries"  # Only needed for relevant external data
```

The build of `autotalys_tools` uses the source files directly. No `DATA_ROOT` installation setting, source-path substitution or large-library download is required to compile its utilities.

## Testing AUTOTALYS

Run from a **separate working directory**, not from the installation source tree, because AUTOTALYS creates nuclide-specific output directories in the current working directory:

```bash
mkdir -p "$HOME/autotalys_test"
cd "$HOME/autotalys_test"
```

A lightweight TALYS-only smoke test that does not require the full external evaluated libraries is:

```bash
"$HOME/autotalys/bin/autotalys" -element Nb -mass 93 -E30 -noendf -noplot
```

To test ENDF-6 production and other enabled tools without FUDGE checking:

```bash
"$HOME/autotalys/bin/autotalys" -element Nb -mass 93 -E30 -nofudge
```

For the broader original covariance-workflow example, use:

```bash
"$HOME/autotalys/bin/autotalys" -element Nb -mass 93 -covar -ntalys 2 -E30
```

The last example is substantially more demanding and requires the relevant optional processing tools (including a working FUDGE installation unless `-nofudge` is specified). These are test commands, not guarantees that every optional feature has been validated on every platform.

If installed somewhere other than `$HOME/autotalys`, replace that prefix with the actual installation path. The executable can be invoked from another working directory.

## Updating individual packages

With a Git installation, update a single component rather than recloning the entire system:

```bash
cd "$HOME/autotalys/tefal"
git pull --ff-only
./install_tefal.bash
```

For changes to AUTOTALYS_TOOLS:

```bash
cd "$HOME/autotalys/autotalys_tools"
git pull --ff-only
./install_autotalys_tools.bash
```

To refresh the small setup repository independently:

```bash
cd "$HOME/autotalys_setup"
git pull --ff-only
```

The copied top-level `install_autotalys.bash` is a snapshot taken when AUTOTALYS was assembled. After updating `autotalys_tools/bin/install_autotalys.bash`, copy it again to the assembled installation root if you want to use its latest version:

```bash
cp "$HOME/autotalys/autotalys_tools/bin/install_autotalys.bash" \
   "$HOME/autotalys/install_autotalys.bash"
```

The no-Git installation has no Git history; obtain new source archives to update it.

## Notes and limitations

- The full evaluated `libraries/` collection is **optional**, not a prerequisite for routine TALYS runs. Individual adoption, comparison or normalization steps may still need external files.
- `naturaltables` deliberately operates on isotopic evaluated tables and therefore needs the requested data under `LIBRARIES_DIR`.
- `interCE` and `psycheCE` use the selected data distributed under `RESONANCETABLES_DIR`; they do not require the full `libraries/` tree for these comparisons.
- The default driver enables several downstream processing/checking stages. Missing optional executables may require the appropriate `-no...` option; a lightweight smoke test is a useful first check.
- A complete, reproducible end-to-end installation across macOS and Linux, including all optional options, still needs testing on each target environment.

## Author

Arjan Koning
