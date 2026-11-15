# AUTOTALYS

AUTOTALYS is a collection of nuclear-reaction and nuclear-data tools for running TALYS calculations, producing evaluated nuclear data libraries, fitting nuclear-reaction data, and generating sensitivity and covariance results. It combines TALYS, TEFAL, TASMAN and supporting programs in one installation while retaining their individual source repositories.

The small **[AUTOTALYS setup repository](https://github.com/arjankoning1/autotalys)** contains the scripts that assemble the system; the scientific codes and databases are maintained separately.

## Contents of this repository

| File | Purpose |
| --- | --- |
| `clone_autotalys.bash` | Clone the complete system from GitHub, retaining Git histories |
| `update_autotalys.bash` | Fetch, fast-forward, and clone package repositories without installing them |
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

OpenMC is an **optional Conda-installed transport code**, not a cloned source repository. The `autoopenmc` wrapper is provided by `autoendf/bin/`, and the overall installer can set up an OpenMC environment when explicitly requested.

The setup obtains only the `n/`, `p/`, `g/`, `d/`, `a/`, `t/`, `h/` and `FY/` directories of EXFORTABLES, rather than cloning the complete repository contents. This is sufficient for using the distributed experimental tables, but **not** for rebuilding the EXFORTABLES database from its original reconstruction inputs.

RESONANCETABLES is downloaded with its existing selected data tables. Reconstructing those tables from primary sources is a separate operation and may require additional databases; it is not part of the standard AUTOTALYS installation.

## Requirements

- macOS or Linux with a Bash shell.
- Git for the recommended clone method; alternatively, `curl` and `tar` for archive downloads.
- A Fortran compiler (for example, `gfortran`), C/C++ compilers, GNU Make and CMake for building the included codes.
- The external programs needed by enabled processing or plotting options, such as Gnuplot and Ghostscript where appropriate.
- Optional OpenMC: Conda (Miniforge recommended); set `INSTALL_OPENMC=1` when running the top-level installer. A working NJOY executable is also required for converting neutron ENDF files to OpenMC HDF5.
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
# Optional: install or verify OpenMC as well
INSTALL_OPENMC=1 ./install_autotalys.bash
```

The second invocation re-runs the main installer; on a fresh installation, use `INSTALL_OPENMC=1 ./install_autotalys.bash` *instead of* the ordinary installation command if you want OpenMC.

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

The current `autotalys_tools/install_autotalys_tools.bash` builds seven free-form Fortran utilities plus `njoycovx`, using `DATA_ROOT` (by default, the parent of `autotalys_tools/`) to configure data paths in **temporary** source copies. It does not modify the checked-out source. The data root must exist, but the full evaluated-library download is not required just to compile the programs. If you move the installation, rerun this installer to update embedded paths. See the AUTOTALYS_TOOLS README for standalone `DATA_ROOT` configuration.

## Optional OpenMC transport validation

OpenMC is **not cloned** by `clone_autotalys.bash` or `download_autotalys.bash`. Its wrapper (`autoopenmc` and `autoopenmc.py`) comes from `autoendf/bin/`; the top-level installer links these entry points into `autotalys/bin/`.

To install or verify OpenMC while installing the assembled system, use:

```bash
cd "$HOME/autotalys"
INSTALL_OPENMC=1 ./install_autotalys.bash
```

With `INSTALL_OPENMC=1`, the installer looks for Conda (including common Miniforge locations), creates or updates the `openmc` environment with `openmc`, `numpy`, and `matplotlib`, verifies the `openmc` executable and Python module, and writes `config/openmc.conf`. `OPENMC_CONDA` may select a Conda executable and `OPENMC_ENV` may select another environment name. If installation fails, AUTOTALYS continues without OpenMC; inspect the warning and verify OpenMC separately. Without `INSTALL_OPENMC=1`, the main installer skips this optional step.

OpenMC additionally needs **neutron nuclear data** for transport. The standalone `autoopenmc` wrapper calls NJOY to convert a specified neutron ENDF evaluation to HDF5, then performs a transport calculation. For comparisons with other evaluations, the optional `LIBRARIES_DIR` collection is needed; `-worldlibs none` avoids that dependency. The full `libraries/` download is **not required** for a single-evaluation neutron-only run.

For example, from a directory containing a valid neutron ENDF file:

```bash
"$HOME/autotalys/bin/autoopenmc" \
  -file n-Fe056.tendl -element Fe -mass 56 \
  -worldlibs none -no-photons
```

The wrapper requires NJOY on `PATH` (or `-njoybin /absolute/path/to/njoy`). Its default transport test uses a 10 cm sphere and 14 MeV isotropic point neutron source; density defaults to 7.874 g/cm³, which should be overridden with `-density` for other materials. It writes neutron leakage data, plots, per-evaluation runs, and `manifest.json` into the chosen output directory (`-outdir`).

For **coupled neutron–photon transport**, obtain the matching *photoatomic* OpenMC HDF5 files and a `cross_sections.xml` pointing to them separately. Set `OPENMC_CROSS_SECTIONS=/path/to/cross_sections.xml` or pass `-photon-xs /path/to/cross_sections.xml` and omit `-no-photons`. Downloading the full evaluated ENDF `libraries/` collection does **not** automatically install these photoatomic HDF5 files or create the XML index.

The high-level AUTOTALYS driver supports `-openmc` for **neutron-projectile, general-purpose ENDF evaluations**; it requires ENDF production to be enabled and currently calls `autoopenmc` with `-no-photons`. Thus `-openmc` in the main driver performs neutron-only leakage validation, while direct `autoopenmc` allows coupled neutron–photon transport. See the [AUTOENDF README](https://github.com/arjankoning1/autoendf#optional-openmc-transport-validation) for command options.

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

## Incremental updates (Git installations)

After the initial installation, use `update_autotalys.bash` from the small
`autotalys_setup` repository rather than cloning the entire system again:

```bash
cd "$HOME/autotalys_setup"
git pull --ff-only

# Preview remote source changes:
bash update_autotalys.bash "$HOME/autotalys" --dry-run

# Fast-forward and clone source repositories:
bash update_autotalys.bash "$HOME/autotalys"

# When ready, install separately:
cd "$HOME/autotalys"
./install_autotalys.bash
```

Other useful modes:

```bash
bash update_autotalys.bash "$HOME/autotalys" --only talys
```

The updater fetches only new Git objects; it also clones any *missing* package
listed in its package manifest. If locally modified tracked files already match
the fetched commit byte-for-byte, it can fast-forward that checkout. Other
local source changes are preserved. It never force-resets diverged branches and
retains EXFORTABLES's sparse checkout.
`--dry-run` still fetches remote Git references but does not change checked-out
files. The updater does not build packages, refresh installed executables, or
change symbolic links; run the installer when you want those changes applied.
An archive-based installation (from `download_autotalys.bash`) cannot be
updated using this Git updater. The optional `libraries/` collection and
external OpenMC environment are not modified.

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
