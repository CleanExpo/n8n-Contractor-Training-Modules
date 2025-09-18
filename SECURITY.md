# Security Policy

## Supported Versions

We take security seriously and will address security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in the Photo Album Organizer Spec Kit, please report it responsibly:

### How to Report

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Email the maintainers directly at: [security contact needed]
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact assessment
   - Suggested fix (if you have one)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your report within 48 hours
- **Investigation**: We will investigate the issue and determine its severity
- **Timeline**: We aim to address critical security issues within 7 days
- **Communication**: We will keep you informed throughout the process
- **Credit**: We will credit you for responsible disclosure (unless you prefer to remain anonymous)

## Security Considerations

### Local Data Storage

This project processes and stores photo metadata locally using SQLite. Consider the following security aspects:

- **File Access**: The application accesses local files and may store file paths
- **Database Security**: SQLite databases are stored locally without encryption by default
- **User Privacy**: No photo data is uploaded to external servers

### Recommended Practices

For users of this project:

1. **File Permissions**: Ensure appropriate file system permissions on your photo directories
2. **Database Location**: Store the SQLite database in a secure location
3. **Backup Security**: Secure any backups of your photo metadata
4. **Network Isolation**: The application should not require network access for core functionality

## Dependencies

We regularly audit our dependencies for security vulnerabilities:

- Python dependencies are managed through `pyproject.toml`
- We use tools like `safety` and `pip-audit` to check for known vulnerabilities
- Critical security updates to dependencies will be prioritized

## Security Updates

Security updates will be:

- Released as patch versions (e.g., 0.1.1, 0.1.2)
- Documented in the [CHANGELOG.md](CHANGELOG.md)
- Announced through appropriate channels

## Scope

This security policy applies to:

- The Photo Album Organizer Spec Kit codebase
- Official documentation and examples
- Build and deployment scripts

It does not cover:

- Third-party dependencies (report to their respective maintainers)
- User-generated content or configurations
- Issues in forked or modified versions

## Security Best Practices for Contributors

When contributing to this project:

1. **Code Review**: All code changes undergo security-focused review
2. **Input Validation**: Validate all user inputs and file paths
3. **Error Handling**: Avoid exposing sensitive information in error messages
4. **Dependencies**: Keep dependencies minimal and up-to-date
5. **Secrets**: Never commit secrets, tokens, or credentials

## Contact

For security-related questions or concerns, please contact the maintainers through the appropriate channels listed in this document.

---

Thank you for helping keep the Photo Album Organizer Spec Kit secure!
