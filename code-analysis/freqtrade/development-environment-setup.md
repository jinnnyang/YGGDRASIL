# Development Environment Setup

Relevant source files

* [.github/workflows/ci.yml](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml)
* [.pre-commit-config.yaml](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.pre-commit-config.yaml)
* [Dockerfile](https://github.com/freqtrade/freqtrade/blob/8e91fea1/Dockerfile)
* [docker/Dockerfile.armhf](https://github.com/freqtrade/freqtrade/blob/8e91fea1/docker/Dockerfile.armhf)
* [pyproject.toml](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml)
* [requirements-dev.txt](https://github.com/freqtrade/freqtrade/blob/8e91fea1/requirements-dev.txt)
* [setup.sh](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh)
* [tests/test\_pip\_audit.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/test_pip_audit.py)

This document describes the process and tools for setting up a development environment for contributing to Freqtrade. It covers the installation script, virtual environment configuration, development dependencies, code quality tools (ruff, mypy, isort), pre-commit hooks, and the testing infrastructure. For CI/CD pipeline configuration and deployment processes, see [CI/CD Pipeline and Docker](/freqtrade/freqtrade/6.2-cicd-pipeline-and-docker). For general installation instructions for end users, see [Installation and Setup](/freqtrade/freqtrade/1.2-installation-and-setup).

## Setup Script Architecture

Freqtrade provides an automated setup script at [setup.sh1-305](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L1-L305) that handles environment initialization across different platforms. The script follows a function-based architecture with platform-specific installers.

### Setup Script Functions

```mermaid
flowchart TD

Entry["setup.sh Entry Point"]
CheckPython["check_installed_python()<br>lines 22-50"]
CheckUV["UV detected?"]
Install["install()<br>lines 239-265"]
Update["update()<br>lines 156-166"]
Reset["reset()<br>lines 205-233"]
UseUV["Use uv pip<br>PIP=uv pip"]
CheckVersion["Check python3.13/12/11"]
CheckPip["check_installed_pip()"]
CommandSwitch["Command Line<br>Argument"]
DetectOS["Detect OS"]
InstallMacOS["install_macos()<br>lines 130-141"]
InstallDebian["install_debian()<br>lines 144-147"]
InstallRedHat["install_redhat()<br>lines 150-153"]
RecreateEnv["recreate_environments()<br>lines 178-202"]
UpdateEnv["updateenv()<br>lines 52-127"]
AskDev["Development<br>Install?"]
DevReqs["requirements-dev.txt"]
SelectReqs["Select requirements"]
AskPlot["Install<br>plotting?"]
AskHyperopt["Install<br>hyperopt?"]
AskFreqAI["Install<br>FreqAI?"]
PipInstall["pip install -r requirements"]
InstallEditable["pip install -e ."]
InstallUI["freqtrade install-ui"]
PreCommit["pre_commit install<br>lines 121-126"]

Entry --> CheckPython
CheckPython --> CheckUV
CheckUV --> UseUV
CheckUV --> CheckVersion
CheckVersion --> CheckPip
Entry --> CommandSwitch
CommandSwitch --> Install
CommandSwitch --> Update
CommandSwitch --> Reset
Install --> DetectOS
DetectOS --> InstallMacOS
DetectOS --> InstallDebian
DetectOS --> InstallRedHat
InstallMacOS --> RecreateEnv
InstallDebian --> RecreateEnv
InstallRedHat --> RecreateEnv
RecreateEnv --> UpdateEnv
Update --> UpdateEnv
Reset --> RecreateEnv
UpdateEnv --> AskDev
AskDev --> DevReqs
AskDev --> SelectReqs
SelectReqs --> AskPlot
SelectReqs --> AskHyperopt
SelectReqs --> AskFreqAI
DevReqs --> PipInstall
AskPlot --> PipInstall
AskHyperopt --> PipInstall
AskFreqAI --> PipInstall
PipInstall --> InstallEditable
InstallEditable --> InstallUI
DevReqs --> PreCommit
```

**Sources:** [setup.sh1-305](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L1-L305)

### Platform Detection and Dependencies

The script detects the operating system and installs platform-specific dependencies:

| Platform | Detection Method | Dependencies Installed | Function |
| --- | --- | --- | --- |
| macOS | `uname -s` == "Darwin" | brew, gettext, libomp | `install_macos()` [setup.sh130-141](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L130-L141) |
| Debian/Ubuntu | `command -v apt-get` | gcc, build-essential, autoconf, libtool, pkg-config, make, wget, git, curl, libpython-dev | `install_debian()` [setup.sh144-147](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L144-L147) |
| RedHat/CentOS | `command -v yum` | gcc, gcc-c++, make, autoconf, libtool, pkg-config, wget, git, python-devel | `install_redhat()` [setup.sh150-153](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L150-L153) |

**Sources:** [setup.sh130-153](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L130-L153)

### UV Package Manager Support

The script automatically detects and uses `uv` if available for faster dependency installation:

```
```
if [ -x "$(command -v uv)" ]; then
    echo "uv detected — using it instead of pip for faster installation."
    PIP="uv pip"
    PYTHON="python3.13"
    UV=true
fi
```
```

When creating virtual environments with `uv`:

```
```
if [ "$UV" = true ] ; then
    uv venv .venv --python=${PYTHON}
else
    ${PYTHON} -m venv .venv
fi
```
```

**Sources:** [setup.sh28-33](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L28-L33) [setup.sh191-196](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L191-L196)

## Development Dependencies Structure

The development dependency chain is hierarchical, with `requirements-dev.txt` including all lower-level requirement files.

### Dependency Inclusion Diagram

```mermaid
flowchart TD

DevReq["requirements-dev.txt"]
CoreReq["requirements.txt"]
PlotReq["requirements-plot.txt"]
HyperoptReq["requirements-hyperopt.txt"]
FreqAIReq["requirements-freqai.txt"]
FreqAIRL["requirements-freqai-rl.txt"]
DocsReq["docs/requirements-docs.txt"]
DevTools["Development Tools"]
Ruff["ruff==0.14.10"]
Mypy["mypy==1.19.1"]
PreCommit["pre-commit==4.5.1"]
Pytest["pytest==9.0.2<br>+ pytest plugins"]
Isort["isort==7.0.0"]
TimeMachine["time-machine==3.2.0"]
Nbconvert["nbconvert==7.16.6"]
MypyTypes["Type stubs:<br>scipy-stubs<br>types-cachetools<br>types-filelock<br>types-requests<br>types-tabulate<br>types-python-dateutil"]
PipAudit["pip-audit==2.10.0"]

DevReq --> CoreReq
DevReq --> PlotReq
DevReq --> HyperoptReq
DevReq --> FreqAIReq
DevReq --> FreqAIRL
DevReq --> DocsReq
DevReq --> DevTools
DevTools --> Ruff
DevTools --> Mypy
DevTools --> PreCommit
DevTools --> Pytest
DevTools --> Isort
DevTools --> TimeMachine
DevTools --> Nbconvert
DevTools --> MypyTypes
DevTools --> PipAudit
```

**Sources:** [requirements-dev.txt1-34](https://github.com/freqtrade/freqtrade/blob/8e91fea1/requirements-dev.txt#L1-L34)

### Core Development Tools

| Tool | Version | Purpose | Configuration File |
| --- | --- | --- | --- |
| `ruff` | 0.14.10 | Fast Python linter and formatter | [pyproject.toml252-295](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L252-L295) |
| `mypy` | 1.19.1 | Static type checker | [pyproject.toml194-217](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L194-L217) |
| `isort` | 7.0.0 | Import statement sorter | [pyproject.toml177-183](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L177-L183) |
| `pre-commit` | 4.5.1 | Git hook manager | [.pre-commit-config.yaml1-89](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.pre-commit-config.yaml#L1-L89) |
| `pytest` | 9.0.2 | Testing framework | [pyproject.toml185-192](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L185-L192) |
| `pip-audit` | 2.10.0 | Security vulnerability scanner | [tests/test\_pip\_audit.py1-93](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/test_pip_audit.py#L1-L93) |

**Sources:** [requirements-dev.txt9-33](https://github.com/freqtrade/freqtrade/blob/8e91fea1/requirements-dev.txt#L9-L33) [pyproject.toml1-347](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L1-L347)

### Pytest Plugin Ecosystem

```mermaid
flowchart TD

Pytest["pytest 9.0.2"]
AsyncIO["pytest-asyncio 1.3.0<br>Async test support"]
Cov["pytest-cov 7.0.0<br>Code coverage"]
Mock["pytest-mock 3.15.1<br>Mocking utilities"]
Random["pytest-random-order 1.2.0<br>Randomize test order"]
Timeout["pytest-timeout 2.4.0<br>Test timeouts"]
Xdist["pytest-xdist 3.8.0<br>Parallel execution"]

Pytest --> AsyncIO
Pytest --> Cov
Pytest --> Mock
Pytest --> Random
Pytest --> Timeout
Pytest --> Xdist
```

**Sources:** [requirements-dev.txt12-18](https://github.com/freqtrade/freqtrade/blob/8e91fea1/requirements-dev.txt#L12-L18)

## Pre-commit Hook System

Pre-commit hooks run automatically before each git commit to enforce code quality standards. The configuration chains multiple tools in sequence.

### Pre-commit Hook Execution Flow

```mermaid
flowchart TD

Commit["git commit"]
PreCommit["pre-commit framework"]
Local["Local Hook:<br>extract-config-json-schema"]
ExtractSchema["python build_helpers/<br>extract_config_json_schema.py"]
Flake8["flake8 7.3.0<br>Linting"]
Flake8Config["pyproject.toml [tool.flake8]"]
Mypy["mypy 1.19.1<br>Type checking"]
MypyDeps["Additional dependencies:<br>types-cachetools<br>types-filelock<br>types-requests<br>types-tabulate<br>types-python-dateutil<br>scipy-stubs<br>SQLAlchemy"]
Isort["isort 7.0.0<br>Import sorting"]
Ruff["ruff 0.14.10"]
RuffCheck["ruff check"]
RuffFormat["ruff format"]
StdHooks["Standard hooks:<br>end-of-file-fixer<br>mixed-line-ending<br>debug-statements<br>check-ast<br>trailing-whitespace"]
ExifStrip["strip-exif 1.2.0<br>Remove EXIF metadata"]
Codespell["codespell v2.4.1<br>Spell checking"]
Zizmor["zizmor v1.19.0<br>GitHub Actions security"]
CheckChanges["Files changed?"]
Fail["Pre-commit FAILS"]
Pass["Continue"]
Success["Commit succeeds"]

Commit --> PreCommit
PreCommit --> Local
Local --> ExtractSchema
PreCommit --> Flake8
Flake8 --> Flake8Config
PreCommit --> Mypy
Mypy --> MypyDeps
PreCommit --> Isort
PreCommit --> Ruff
Ruff --> RuffCheck
Ruff --> RuffFormat
PreCommit --> StdHooks
PreCommit --> ExifStrip
PreCommit --> Codespell
PreCommit --> Zizmor
ExtractSchema --> CheckChanges
CheckChanges --> Fail
CheckChanges --> Pass
Flake8 --> Pass
Mypy --> Pass
Isort --> Pass
RuffCheck --> Pass
RuffFormat --> Pass
StdHooks --> Pass
ExifStrip --> Pass
Codespell --> Pass
Zizmor --> Pass
Pass --> Success
```

**Sources:** [.pre-commit-config.yaml1-89](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.pre-commit-config.yaml#L1-L89)

### Pre-commit Installation

Pre-commit hooks are automatically installed when running `setup.sh --install` with development dependencies:

```
```
if [[ $dev =~ ^[Yy]$ ]]; then
    ${PYTHON} -m pre_commit install
    if [ $? -ne 0 ]; then
        echo "Failed installing pre-commit"
        exit 1
    fi
fi
```
```

Manual installation:

```
```
source .venv/bin/activate
pre-commit install
```
```

**Sources:** [setup.sh120-126](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L120-L126)

## Code Quality Tool Configuration

All code quality tools are configured through [pyproject.toml1-347](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L1-L347) providing centralized configuration management.

### Tool Configuration Mapping

```mermaid
flowchart TD

PyProject["pyproject.toml"]
RuffConfig["[tool.ruff]<br>lines 252-295"]
MypyConfig["[tool.mypy]<br>lines 194-217"]
IsortConfig["[tool.isort]<br>lines 177-183"]
PytestConfig["[tool.pytest.ini_options]<br>lines 185-192"]
Flake8Config["[tool.flake8]<br>lines 329-342"]
CodespellConfig["[tool.codespell]<br>lines 344-346"]
RuffLine["line-length = 100"]
RuffLint["[tool.ruff.lint]<br>Enabled checks:<br>C90, B, F, E, W, UP, I,<br>A, TID, YTT, S, PTH,<br>RUF, ASYNC, NPY"]
RuffMccabe["[tool.ruff.lint.mccabe]<br>max-complexity = 12"]
RuffIgnore["Per-file ignores"]
MypyIgnore["ignore_missing_imports = true"]
MypyWarn["warn_unused_ignores = true"]
MypyPlugin["SQLAlchemy plugin"]
MypyOverrides["Test file overrides"]
IsortLine["line_length = 100"]
IsortProfile["profile = black"]
IsortSkip["skip_glob patterns"]
PytestLog["Log format config"]
PytestAsync["asyncio_mode = auto"]
PytestDist["addopts = --dist loadscope"]

PyProject --> RuffConfig
PyProject --> MypyConfig
PyProject --> IsortConfig
PyProject --> PytestConfig
PyProject --> Flake8Config
PyProject --> CodespellConfig
RuffConfig --> RuffLine
RuffConfig --> RuffLint
RuffConfig --> RuffMccabe
RuffConfig --> RuffIgnore
MypyConfig --> MypyIgnore
MypyConfig --> MypyWarn
MypyConfig --> MypyPlugin
MypyConfig --> MypyOverrides
IsortConfig --> IsortLine
IsortConfig --> IsortProfile
IsortConfig --> IsortSkip
PytestConfig --> PytestLog
PytestConfig --> PytestAsync
PytestConfig --> PytestDist
```

**Sources:** [pyproject.toml177-346](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L177-L346)

### Ruff Configuration Details

Ruff is configured to replace multiple legacy tools (flake8, pylint, pyupgrade) with a single fast linter:

| Setting | Value | Purpose |
| --- | --- | --- |
| `line-length` | 100 | Maximum line length |
| `extend-exclude` | `.env`, `.venv` | Directories to skip |
| Enabled rule sets | C90 (mccabe), B (bugbear), F (pyflakes), E/W (pycodestyle), UP (pyupgrade), I (isort), A (builtins), TID (tidy-imports), YTT (2020), S (bandit), PTH (pathlib), RUF (ruff-specific), ASYNC, NPY (numpy) | Comprehensive linting |
| `max-complexity` | 12 | Maximum cyclomatic complexity |

**Sources:** [pyproject.toml252-298](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L252-L298)

### Mypy Type Checking Configuration

```
```
[tool.mypy]
ignore_missing_imports = true
namespace_packages = false
warn_unused_ignores = true
exclude = [
    '^build_helpers\.py$',
    '^ft_client/build/.*$',
]
plugins = [
  "sqlalchemy.ext.mypy.plugin"
]
```
```

Test files have relaxed type checking:

```
```
[[tool.mypy.overrides]]
module = "tests.*"
ignore_errors = true
```
```

**Sources:** [pyproject.toml194-217](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L194-L217)

### isort Import Organization

```
```
[tool.isort]
line_length = 100
profile = "black"
lines_after_imports = 2
skip_glob = ["**/.env*", "**/env/*", "**/.venv/*", "**/docs/*", "**/user_data/*"]
known_first_party = ["freqtrade_client"]
```
```

**Sources:** [pyproject.toml177-183](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L177-L183)

## Testing Infrastructure

The testing system uses pytest with extensive parallel execution and code coverage tracking.

### Test Execution Configuration

```mermaid
flowchart TD

CIWorkflow[".github/workflows/ci.yml"]
TestMatrix["Test Matrix:<br>6 OS × 4 Python versions<br>= 24 configurations"]
OS["OS Variants:<br>ubuntu-22.04, ubuntu-24.04<br>macos-14, macos-15<br>windows-2022, windows-2025"]
Python["Python Versions:<br>3.11, 3.12, 3.13, 3.14"]
InstallStep["Installation Steps"]
SetupUV["Install uv package manager<br>astral-sh/setup-uv@681c641"]
InstallDeps["uv pip install -r requirements-dev.txt<br>uv pip install -e ft_client/<br>uv pip install -e ."]
StandardTests["Standard Tests<br>pytest --random-order<br>--durations 20 -n auto"]
CoverageTests["Coverage Tests<br>Ubuntu 24.04 + Python 3.12<br>pytest --random-order --cov"]
Codecov["Upload to Codecov"]
ExtractSchema["Extract JSON schema"]
CheckRepo["Verify no changes:<br>git status --porcelain"]
BacktestTest["Backtesting Test:<br>freqtrade backtesting<br>--datadir tests/testdata<br>--strategy-list AwesomeStrategy"]
HyperoptTest["Hyperopt Test:<br>freqtrade hyperopt<br>--datadir tests/testdata<br>-e 6"]
LintSteps["Linting Steps"]
IsortCheck["isort --check ."]
RuffCheck["ruff check --output-format=github"]
RuffFormatCheck["ruff format --check"]
MypyCheck["mypy freqtrade scripts tests"]

CIWorkflow --> TestMatrix
TestMatrix --> OS
TestMatrix --> Python
CIWorkflow --> InstallStep
InstallStep --> SetupUV
SetupUV --> InstallDeps
InstallDeps --> StandardTests
InstallDeps --> CoverageTests
CoverageTests --> Codecov
StandardTests --> ExtractSchema
CoverageTests --> ExtractSchema
ExtractSchema --> CheckRepo
CheckRepo --> BacktestTest
BacktestTest --> HyperoptTest
HyperoptTest --> LintSteps
LintSteps --> IsortCheck
LintSteps --> RuffCheck
LintSteps --> RuffFormatCheck
LintSteps --> MypyCheck
```

**Sources:** [.github/workflows/ci.yml1-430](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml#L1-L430)

### Pytest Command Line Options

From the CI configuration [.github/workflows/ci.yml70-75](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml#L70-L75):

| Option | Purpose |
| --- | --- |
| `--random-order` | Randomize test execution order to detect hidden dependencies |
| `--durations 20` | Show 20 slowest tests |
| `-n auto` | Parallel execution using all available CPU cores (pytest-xdist) |
| `--cov=freqtrade --cov=freqtrade_client` | Enable code coverage tracking |
| `--cov-config=.coveragerc` | Coverage configuration file |
| `--longrun` | Include long-running tests (online tests) |

**Sources:** [.github/workflows/ci.yml70-273](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml#L70-L273)

### pytest.ini Configuration

```
```
[tool.pytest.ini_options]
log_format = "%(asctime)s %(levelname)s %(message)s"
log_date_format = "%Y-%m-%d %H:%M:%S"
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"
addopts = "--dist loadscope"
```
```

The `--dist loadscope` option distributes tests to workers by module, ensuring module-scoped fixtures work correctly in parallel execution.

**Sources:** [pyproject.toml185-192](https://github.com/freqtrade/freqtrade/blob/8e91fea1/pyproject.toml#L185-L192)

## Security Vulnerability Scanning

Freqtrade includes automated security scanning using `pip-audit` to detect known vulnerabilities in dependencies.

### pip-audit Integration

```mermaid
flowchart TD

TestSuite["Test Suite"]
PipAuditTest["test_pip_audit.py"]
RunAudit["subprocess.run:<br>python -m pip_audit"]
Options["Options:<br>--progress-spinner=off<br>--ignore-vuln CVE-2025-53000<br>--skip-editable"]
CheckResult["Return code"]
Success["No vulnerabilities found"]
CheckOutput["Output analysis"]
Fail["Fail test with details"]
FailError["Fail with error message"]
VersionCheck["test_pip_audit_runs_successfully()<br>Smoke test: pip-audit --version"]

TestSuite --> PipAuditTest
PipAuditTest --> RunAudit
RunAudit --> Options
Options --> CheckResult
CheckResult --> Success
CheckResult --> CheckOutput
CheckOutput --> Fail
CheckOutput --> FailError
Success --> VersionCheck
```

**Sources:** [tests/test\_pip\_audit.py1-93](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/test_pip_audit.py#L1-L93)

The test ignores `CVE-2025-53000` (nbconvert Windows vulnerability) as documented in [tests/test\_pip\_audit.py20-22](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/test_pip_audit.py#L20-L22):

```
```
# Note: CVE-2025-53000 (nbconvert Windows vulnerability) is ignored as it only affects
# Windows platforms and is a known acceptable risk for this project.
```
```

**Sources:** [tests/test\_pip\_audit.py14-72](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/test_pip_audit.py#L14-L72) [requirements-dev.txt33](https://github.com/freqtrade/freqtrade/blob/8e91fea1/requirements-dev.txt#L33-L33)

## CI/CD Integration Points

The development environment integrates tightly with the CI/CD pipeline to ensure local development matches CI behavior.

### CI Test Matrix

From [.github/workflows/ci.yml26-28](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml#L26-L28):

```
```
matrix:
  os: [ "ubuntu-22.04", "ubuntu-24.04", "macos-14", "macos-15" , "windows-2022", "windows-2025" ]
  python-version: ["3.11", "3.12", "3.13", "3.14"]
```
```

This creates 24 test configurations (6 OS × 4 Python versions) that run on every push, pull request, and schedule.

**Sources:** [.github/workflows/ci.yml22-29](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml#L22-L29)

### UV Package Manager in CI

The CI uses the same `uv` package manager detection as the local setup script:

```
```
- name: Install uv
  uses: astral-sh/setup-uv@681c641aba71e4a1c380be3ab5e12ad51f415867 # v7.1.6
  with:
    activate-environment: true
    enable-cache: true
    python-version: ${{ matrix.python-version }}
    cache-dependency-glob: "requirements**.txt"
    cache-suffix: "${{ matrix.python-version }}"
```
```

**Sources:** [.github/workflows/ci.yml40-47](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml#L40-L47)

### Pre-commit CI Job

A dedicated CI job runs pre-commit checks separately [.github/workflows/ci.yml195-206](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml#L195-L206):

```
```
pre-commit:
  name: "Pre-commit checks"
  runs-on: ubuntu-22.04
  steps:
  - uses: actions/checkout@v6.0.1
  - uses: actions/setup-python@v6
    with:
      python-version: "3.12"
  - uses: pre-commit/action@2c7b3805fd2a0fd8c1884dcaebf91fc102a13ecd # v3.0.1
```
```

**Sources:** [.github/workflows/ci.yml195-206](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml#L195-L206)

## Docker Development Environment

For developers preferring containerized environments, Freqtrade provides multi-stage Dockerfiles that mirror the local setup process.

### Dockerfile Structure

```mermaid
flowchart TD

Dockerfile["Dockerfile"]
Base["FROM python:3.13.11-slim-trixie AS base<br>Base environment setup"]
BaseEnv["Environment Variables:<br>LANG=C.UTF-8<br>LC_ALL=C.UTF-8<br>PYTHONDONTWRITEBYTECODE=1<br>PYTHONFAULTHANDLER=1<br>PATH=/home/ftuser/.local/bin:PATH<br>FT_APP_ENV=docker"]
BaseSetup["System setup:<br>mkdir /freqtrade<br>apt-get install sudo libatlas3-base<br>curl sqlite3 libgomp1<br>useradd ftuser"]
PythonDeps["FROM base AS python-deps<br>Build dependencies"]
BuildTools["apt-get install build-essential<br>libssl-dev git libffi-dev<br>libgfortran5 pkg-config cmake gcc<br>pip install --upgrade pip wheel"]
InstallReqs["COPY requirements.txt<br>requirements-hyperopt.txt<br>pip install --user numpy<br>pip install --user -r requirements-hyperopt.txt"]
Runtime["FROM base AS runtime-image<br>Production runtime"]
CopyDeps["COPY --from=python-deps<br>/home/ftuser/.local"]
CopyCode["COPY . /freqtrade/"]
InstallBot["pip install -e . --user<br>mkdir user_data/<br>freqtrade install-ui"]
Entry["ENTRYPOINT: freqtrade<br>CMD: trade"]

Dockerfile --> Base
Base --> BaseEnv
Base --> BaseSetup
Dockerfile --> PythonDeps
PythonDeps --> BuildTools
PythonDeps --> InstallReqs
Dockerfile --> Runtime
Runtime --> CopyDeps
Runtime --> CopyCode
Runtime --> InstallBot
Runtime --> Entry
```

**Sources:** [Dockerfile1-54](https://github.com/freqtrade/freqtrade/blob/8e91fea1/Dockerfile#L1-L54)

### ARM-specific Docker Configuration

For ARM platforms (like Raspberry Pi), a specialized Dockerfile exists at [docker/Dockerfile.armhf1-58](https://github.com/freqtrade/freqtrade/blob/8e91fea1/docker/Dockerfile.armhf#L1-L58) that uses piwheels for precompiled ARM binaries:

```
```
RUN echo "[global]\nextra-index-url=https://www.piwheels.org/simple" > /etc/pip.conf
```
```

**Sources:** [docker/Dockerfile.armhf1-58](https://github.com/freqtrade/freqtrade/blob/8e91fea1/docker/Dockerfile.armhf#L1-L58)

## Development Workflow Summary

### Initial Setup

```
```
# Clone repository
git clone https://github.com/freqtrade/freqtrade.git
cd freqtrade

# Run setup script (install option)
./setup.sh --install
# Answer prompts:
# - Development install? [y/N] - Answer 'y' for full dev environment
# - This installs all dependencies and sets up pre-commit hooks

# Activate virtual environment
source .venv/bin/activate
```
```

**Sources:** [setup.sh239-265](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L239-L265)

### Daily Development

```
```
# Activate environment
source .venv/bin/activate

# Run tests
pytest --random-order -n auto

# Run linting manually
isort --check .
ruff check
ruff format --check
mypy freqtrade scripts tests

# Or let pre-commit run all checks
pre-commit run --all-files
```
```

**Sources:** [.github/workflows/ci.yml140-155](https://github.com/freqtrade/freqtrade/blob/8e91fea1/.github/workflows/ci.yml#L140-L155)

### Updating Dependencies

```
```
# Pull latest changes
git pull

# Update environment
./setup.sh --update
# This will:
# - Update pip dependencies
# - Reinstall the package in editable mode
# - Update freqUI
```
```

**Sources:** [setup.sh156-166](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L156-L166)

### Reset Environment

```
```
# Hard reset (removes all local changes)
./setup.sh --reset
# This will:
# - Reset git branch to origin
# - Delete and recreate virtual environment
# - Reinstall all dependencies
```
```

**Sources:** [setup.sh205-233](https://github.com/freqtrade/freqtrade/blob/8e91fea1/setup.sh#L205-L233)