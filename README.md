# 🌱 Photo Album Organizer - Spec Kit

Build high-quality photo organization software faster using Spec-Driven Development.

An effort to allow organizations to focus on product scenarios rather than writing undifferentiated code with the help of Spec-Driven Development.

## Table of Contents
- [🤔 What is Spec-Driven Development?](#-what-is-spec-driven-development)
- [⚡ Get started](#-get-started)
- [📽️ Project Overview](#️-project-overview)
- [🔧 Specify CLI Reference](#-specify-cli-reference)
- [📚 Core philosophy](#-core-philosophy)
- [🌟 Development phases](#-development-phases)
- [🔧 Prerequisites](#-prerequisites)
- [📖 Learn more](#-learn-more)
- [👥 Maintainers](#-maintainers)
- [💬 Support](#-support)
- [📄 License](#-license)

## 🤔 What is Spec-Driven Development?

Spec-Driven Development flips the script on traditional software development. For decades, code has been king — specifications were just scaffolding we built and discarded once the "real work" of coding began. Spec-Driven Development changes this: specifications become executable, directly generating working implementations rather than just guiding them.

## ⚡ Get started

1. **Install Specify**
   Initialize your project depending on the coding agent you're using:
   ```bash
   uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME>
   ```

2. **Create the spec**
   Use the `/specify` command to describe what you want to build. Focus on the what and why, not the tech stack.
   ```
   /specify Build an application that can help me organize my photos in separate photo albums. Albums are grouped by date and can be re-organized by dragging and dropping on the main page. Albums are never in other nested albums. Within each album, photos are previewed in a tile-like interface.
   ```

3. **Create a technical implementation plan**
   Use the `/plan` command to provide your tech stack and architecture choices.
   ```
   /plan The application uses Vite with minimal number of libraries. Use vanilla HTML, CSS, and JavaScript as much as possible. Images are not uploaded anywhere and metadata is stored in a local SQLite database.
   ```

4. **Break down and implement**
   Use `/tasks` to create an actionable task list, then ask your agent to implement the feature.

## 📽️ Project Overview

This Photo Album Organizer demonstrates Spec-Driven Development principles through:

- **Intent-driven development**: Clear specifications define requirements before implementation
- **Rich specification creation**: Detailed specs guide development decisions
- **Multi-step refinement**: Iterative improvement rather than one-shot generation
- **AI-assisted implementation**: Leveraging advanced AI capabilities for code generation

## 🔧 Prerequisites

- Linux/macOS (or WSL2 on Windows)
- AI coding agent: Claude Code, GitHub Copilot, Gemini CLI, Cursor, Qwen CLI or opencode
- uv for package management
- Python 3.11+
- Git

## 📚 Core philosophy

Spec-Driven Development is a structured process that emphasizes:

- Intent-driven development where specifications define the "what" before the "how"
- Rich specification creation using guardrails and organizational principles
- Multi-step refinement rather than one-shot code generation from prompts
- Heavy reliance on advanced AI model capabilities for specification interpretation

## 🌟 Development phases

| Phase | Focus | Key Activities |
|-------|-------|----------------|
| 0-to-1 Development ("Greenfield") | Generate from scratch | Start with high-level requirements<br>Generate specifications<br>Plan implementation steps<br>Build production-ready applications |
| Creative Exploration | Parallel implementations | Explore diverse solutions<br>Support multiple technology stacks & architectures<br>Experiment with UX patterns |
| Iterative Enhancement ("Brownfield") | Brownfield modernization | Add features iteratively<br>Modernize legacy systems<br>Adapt processes |

## 📖 Learn more

- [Complete Spec-Driven Development Methodology](docs/spec-driven.md) - Deep dive into the full process
- [Photo Album Application Specification](docs/PhotoAlbumApp.spec.md) - Project specification
- [Implementation Plan](docs/PhotoAlbumApp.plan.md) - Technical implementation plan

## 👥 Maintainers

- Den Delimarsky (@localden)
- John Lam (@jflam)

## 💬 Support

For support, please open a GitHub issue. We welcome bug reports, feature requests, and questions about using Spec-Driven Development.

## 📄 License

This project is licensed under the terms of the MIT open source license. Please refer to the [LICENSE](LICENSE) file for the full terms.

---

*This project is heavily influenced by and based on the work and research of John Lam.*
