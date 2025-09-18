# Contributing to Photo Album Organizer Spec Kit

Thank you for your interest in contributing to the Photo Album Organizer Spec Kit! This project demonstrates Spec-Driven Development principles and welcomes contributions that help improve the methodology and implementation.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Process](#development-process)
- [Style Guidelines](#style-guidelines)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Install dependencies: `uv sync`
4. Create a new branch for your changes
5. Make your changes
6. Test your changes
7. Submit a pull request

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include:

- A clear and descriptive title
- Steps to reproduce the problem
- Expected behavior
- Actual behavior
- System information (OS, Python version, etc.)
- Screenshots if applicable

### Suggesting Features

Feature suggestions are welcome! Please provide:

- A clear description of the feature
- Use cases and examples
- How it fits with Spec-Driven Development principles
- Any potential implementation considerations

### Contributing Code

1. **Pick an issue**: Look for issues labeled `good first issue` or `help wanted`
2. **Discuss first**: For significant changes, open an issue to discuss your approach
3. **Follow the spec-driven process**: Create specifications before implementing
4. **Write tests**: Ensure your code is well-tested
5. **Update documentation**: Keep docs current with your changes

## Development Process

### Spec-Driven Development Workflow

This project follows its own methodology:

1. **Specification**: Define what you want to build in `docs/`
2. **Planning**: Create implementation plans in `docs/`
3. **Implementation**: Build according to the specifications
4. **Testing**: Validate against the original specifications

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/your-username/photo-album-spec-kit.git
cd photo-album-spec-kit

# Install dependencies
uv sync

# Run tests
pytest

# Run linting
ruff check .
black --check .

# Format code
black .
ruff --fix .
```

## Style Guidelines

### Python Code

- Follow [PEP 8](https://pep8.org/)
- Use [Black](https://github.com/psf/black) for code formatting
- Use [Ruff](https://github.com/astral-sh/ruff) for linting
- Write docstrings for all functions and classes
- Use type hints where appropriate

### Documentation

- Use clear, concise language
- Follow the existing documentation structure
- Include examples where helpful
- Update the changelog for significant changes

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
- `feat: add drag-and-drop support for album reordering`
- `fix: resolve SQLite connection issue on Windows`
- `docs: update specification examples`

## Submitting Changes

1. **Create a branch**: Use a descriptive name like `feat/album-sorting` or `fix/db-connection`
2. **Make your changes**: Follow the development process above
3. **Test thoroughly**: Ensure all tests pass and add new tests if needed
4. **Update documentation**: Keep specs and docs current
5. **Create a pull request**: 
   - Use a clear title and description
   - Reference any related issues
   - Include screenshots for UI changes
   - Ensure CI passes

### Pull Request Process

1. Ensure your PR has a clear description of what it does
2. Link to any relevant issues
3. Ensure all tests pass
4. Request review from maintainers
5. Address any feedback
6. Once approved, a maintainer will merge your PR

## Getting Help

- **Issues**: Use GitHub issues for bug reports and feature requests
- **Discussions**: Use GitHub Discussions for questions and community chat
- **Email**: Contact maintainers directly for security issues

## Recognition

Contributors are recognized in:
- The project README
- Release notes
- The contributor section of documentation

Thank you for contributing to the Photo Album Organizer Spec Kit!
