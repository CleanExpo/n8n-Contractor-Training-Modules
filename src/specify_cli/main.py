"""Main CLI entry point for Photo Album Organizer Spec Kit."""

import click
from pathlib import Path
import sys
import os


@click.group()
@click.version_option()
def cli():
    """Photo Album Organizer Spec Kit - Build high-quality photo organization software with Spec-Driven Development."""
    pass


@cli.command()
@click.argument('project_name', required=False)
@click.option('--ai', type=click.Choice(['claude', 'gemini', 'copilot', 'opencode', 'cursor']), 
              help='AI assistant to use')
@click.option('--script', type=click.Choice(['sh', 'ps']), default='sh', 
              help='Script variant to use: sh (bash/zsh) or ps (PowerShell)')
@click.option('--ignore-agent-tools', is_flag=True, 
              help='Skip checks for AI agent tools like Claude Code')
@click.option('--no-git', is_flag=True, 
              help='Skip git repository initialization')
@click.option('--here', is_flag=True, 
              help='Initialize project in the current directory instead of creating a new one')
@click.option('--skip-tls', is_flag=True, 
              help='Skip SSL/TLS verification (not recommended)')
@click.option('--debug', is_flag=True, 
              help='Enable detailed debug output for troubleshooting')
def init(project_name, ai, script, ignore_agent_tools, no_git, here, skip_tls, debug):
    """Initialize a new Photo Album Organizer project from the latest template."""
    
    if debug:
        click.echo("Debug mode enabled")
    
    if here:
        project_path = Path.cwd()
        project_name = project_path.name
    else:
        if not project_name:
            click.echo("Error: PROJECT_NAME is required unless using --here flag")
            sys.exit(1)
        project_path = Path.cwd() / project_name
        
        if project_path.exists():
            click.echo(f"Error: Directory '{project_name}' already exists")
            sys.exit(1)
        
        project_path.mkdir(parents=True, exist_ok=True)
    
    click.echo(f"Initializing Photo Album Organizer project: {project_name}")
    click.echo(f"Project path: {project_path}")
    
    # Create basic project structure
    _create_project_structure(project_path, debug)
    
    # Initialize git repository
    if not no_git:
        _init_git_repo(project_path, debug)
    
    # Set up AI assistant configuration
    if ai:
        _setup_ai_assistant(project_path, ai, debug)
    
    click.echo(f"\n✓ Successfully initialized project '{project_name}'")
    click.echo("\nNext steps:")
    click.echo("1. Use /specify to describe your photo album features")
    click.echo("2. Use /plan to define your technical implementation")
    click.echo("3. Use /tasks to break down the work")
    

@cli.command()
def check():
    """Check for installed tools (git, AI assistants, etc.)."""
    click.echo("Checking system requirements...")
    
    tools = {
        'git': _check_git(),
        'python': _check_python(),
        'uv': _check_uv(),
    }
    
    for tool, status in tools.items():
        status_icon = "✓" if status else "✗"
        click.echo(f"{status_icon} {tool}: {'Available' if status else 'Not found'}")
    
    if all(tools.values()):
        click.echo("\n✓ All required tools are available")
    else:
        click.echo("\n✗ Some required tools are missing")


def _create_project_structure(project_path: Path, debug: bool = False):
    """Create the basic project directory structure."""
    dirs = [
        'docs',
        'src',
        'tests',
        'templates',
        'scripts',
        '.github/workflows'
    ]
    
    for dir_name in dirs:
        dir_path = project_path / dir_name
        dir_path.mkdir(parents=True, exist_ok=True)
        if debug:
            click.echo(f"Created directory: {dir_path}")
    
    # Create basic files
    files = {
        'README.md': _get_readme_template(),
        'pyproject.toml': _get_pyproject_template(),
        '.gitignore': _get_gitignore_template(),
        'docs/specification.md': _get_spec_template(),
        'docs/plan.md': _get_plan_template(),
    }
    
    for file_name, content in files.items():
        file_path = project_path / file_name
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content)
        if debug:
            click.echo(f"Created file: {file_path}")


def _init_git_repo(project_path: Path, debug: bool = False):
    """Initialize git repository."""
    import subprocess
    try:
        subprocess.run(['git', 'init'], cwd=project_path, check=True, capture_output=True)
        if debug:
            click.echo("Initialized git repository")
    except subprocess.CalledProcessError:
        click.echo("Warning: Failed to initialize git repository")


def _setup_ai_assistant(project_path: Path, ai: str, debug: bool = False):
    """Set up AI assistant configuration."""
    config_file = project_path / '.ai-config.json'
    config = {
        'assistant': ai,
        'project_type': 'photo-album-organizer',
        'framework': 'spec-driven-development'
    }
    
    import json
    config_file.write_text(json.dumps(config, indent=2))
    if debug:
        click.echo(f"Created AI configuration for {ai}")


def _check_git() -> bool:
    """Check if git is available."""
    import subprocess
    try:
        subprocess.run(['git', '--version'], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def _check_python() -> bool:
    """Check if Python 3.11+ is available."""
    return sys.version_info >= (3, 11)


def _check_uv() -> bool:
    """Check if uv is available."""
    import subprocess
    try:
        subprocess.run(['uv', '--version'], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def _get_readme_template() -> str:
    """Get README template content."""
    return """# Photo Album Organizer

A photo organization application built with Spec-Driven Development principles.

## Overview

This project demonstrates Spec-Driven Development by building a photo album organizer that helps users organize their photos into albums grouped by date with drag-and-drop functionality.

## Getting Started

1. Review the [specification](docs/specification.md)
2. Check the [implementation plan](docs/plan.md)
3. Run the application

## Features

- Create photo albums grouped by date
- Drag and drop album reorganization
- Tile-based photo preview interface
- Local SQLite database storage
- No photo uploads - files stay local

## Tech Stack

- Vite for build tooling
- Vanilla HTML, CSS, JavaScript
- SQLite for metadata storage
- Minimal external dependencies

## Development

```bash
# Install dependencies
uv sync

# Run development server
npm run dev

# Run tests
npm test
```
"""


def _get_pyproject_template() -> str:
    """Get pyproject.toml template."""
    return """[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "photo-album-organizer"
dynamic = ["version"]
description = "Photo Album Organizer built with Spec-Driven Development"
readme = "README.md"
requires-python = ">=3.11"
license = "MIT"
authors = [
    { name = "Your Name" },
]
dependencies = [
    "click>=8.0.0",
]

[project.scripts]
photo-album = "src.main:main"
"""


def _get_gitignore_template() -> str:
    """Get .gitignore template."""
    return """# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Project specific
*.sqlite
*.db
node_modules/
dist/
.temp/
"""


def _get_spec_template() -> str:
    """Get specification template."""
    return """# Photo Album Organizer - Specification

## Overview

Build an application to help users organize their photos into separate photo albums with intuitive management features.

## Features

### Photo Albums
- Create multiple photo albums
- Albums grouped by date
- No nested albums allowed
- Drag and drop reorganization

### Photo Management
- Add photos to albums from local storage
- Remove photos from albums
- Tile-based photo preview interface
- Local file storage (no uploads)

### User Interface
- Responsive and modern design
- Main page with album overview
- Individual album views
- Drag and drop interactions

## Non-Functional Requirements
- Fast loading and responsive UI
- Efficient handling of large photo collections
- Local data storage only
- Cross-platform compatibility

## Constraints
- No nested albums
- No photo uploads to external servers
- Minimal external dependencies
"""


def _get_plan_template() -> str:
    """Get implementation plan template."""
    return """# Photo Album Organizer - Implementation Plan

## Project Setup
- Initialize with Vite for fast development
- Use vanilla HTML, CSS, and JavaScript
- Minimal external libraries
- SQLite for local database

## Architecture

### Frontend
- Main page: Album grid with drag/drop
- Album page: Photo tile interface
- Responsive CSS Grid layout
- Vanilla JavaScript for interactions

### Data Storage
- SQLite database for metadata
- File system for photo storage
- Album and photo relationship tracking
- Date-based grouping logic

### Core Components
1. Album Manager - CRUD operations for albums
2. Photo Manager - Handle photo file operations
3. UI Controller - Handle user interactions
4. Database Layer - SQLite operations
5. Drag & Drop Handler - Album reordering

## Development Steps
1. Set up Vite project structure
2. Create SQLite database schema
3. Implement album CRUD operations
4. Build main page UI
5. Add drag and drop functionality
6. Implement album detail view
7. Add photo management features
8. Testing and optimization

## Technology Choices
- **Vite**: Fast build tooling and dev server
- **SQLite**: Lightweight local database
- **Vanilla JS**: Minimal dependencies, better performance
- **CSS Grid/Flexbox**: Modern responsive layouts
- **File API**: Local file access and preview
"""


def main():
    """Main entry point."""
    cli()


if __name__ == '__main__':
    main()
