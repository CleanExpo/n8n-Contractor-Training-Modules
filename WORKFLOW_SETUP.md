# GitHub Workflow Setup

## Overview

The CI/CD workflow file was temporarily removed during the initial push due to OAuth permission restrictions. The GitHub OAuth App doesn't have the `workflow` scope required to create or update workflow files.

## Manual Setup

To add the CI/CD workflow, create the following file manually through the GitHub web interface:

### File: `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.11", "3.12"]

    steps:
    - uses: actions/checkout@v4
    
    - name: Install uv
      uses: astral-sh/setup-uv@v2
      with:
        version: "latest"
    
    - name: Set up Python ${{ matrix.python-version }}
      run: uv python install ${{ matrix.python-version }}
    
    - name: Install dependencies
      run: uv sync --all-extras --dev
    
    - name: Lint with ruff
      run: uv run ruff check .
    
    - name: Check formatting with black
      run: uv run black --check .
    
    - name: Type check with mypy
      run: uv run mypy src/specify_cli
    
    - name: Run tests
      run: uv run pytest
    
    - name: Test CLI installation
      run: |
        uv run specify --help
        uv run specify check

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Install uv
      uses: astral-sh/setup-uv@v2
    
    - name: Set up Python
      run: uv python install 3.11
    
    - name: Install dependencies
      run: uv sync --dev
    
    - name: Run safety check
      run: uv run safety check
```

## How to Add

1. Go to your GitHub repository: https://github.com/CleanExpo/n8n-Contractor-Training-Modules
2. Click on "Add file" > "Create new file"
3. Type `.github/workflows/ci.yml` as the filename
4. Paste the YAML content above
5. Commit the file

This will enable continuous integration for your project, running tests, linting, and security checks on every push and pull request.
