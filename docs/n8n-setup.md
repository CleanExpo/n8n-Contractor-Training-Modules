# n8n Development Environment Setup

## Overview

This project includes a Docker-based n8n development environment configured for contractor training modules. The setup enables community packages and provides API access for automated workflows.

## Configuration

### Docker Compose

The `docker-compose.yml` file configures n8n with the following features:

- **Community Packages**: Enabled for custom node installation
- **Tool Usage**: Allows community packages to use built-in modules
- **API Access**: Personal access tokens enabled for CLI integration
- **Basic Authentication**: Protects the web UI
- **Persistent Storage**: Data persisted in Docker volumes

### Environment Variables

| Variable | Value | Description |
|----------|--------|-------------|
| `N8N_HOST` | localhost | Host for n8n instance |
| `N8N_PORT` | 5678 | Port for web interface |
| `N8N_PROTOCOL` | http | Protocol (http/https) |
| `N8N_COMMUNITY_PACKAGES_ENABLED` | true | Allow community node installation |
| `N8N_COMMUNITY_PACKAGES_ALLOW_BUILTIN_MODULES` | true | Allow access to Node.js built-ins |
| `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE` | true | Enable tool usage in community packages |
| `N8N_BASIC_AUTH_ACTIVE` | true | Enable basic authentication |
| `N8N_BASIC_AUTH_USER` | admin | Username for web UI |
| `N8N_BASIC_AUTH_PASSWORD` | please-change-me | Password for web UI |
| `N8N_PERSONAL_ACCESS_TOKENS_ENABLED` | true | Enable API tokens |
| `N8N_PERSONAL_ACCESS_TOKENS_TOKENS_0_NAME` | cli | Token name |
| `N8N_PERSONAL_ACCESS_TOKENS_TOKENS_0_VALUE` | cli-dev-token | Token value |

## Getting Started

### Prerequisites

- Docker Desktop installed and running
- PowerShell (Windows) or Bash (Linux/macOS)

### Starting n8n

#### Windows (PowerShell)
```powershell
.\scripts\start-n8n.ps1
```

#### Cross-platform (Docker Compose)
```bash
docker-compose up -d
```

### Accessing n8n

- **Web Interface**: http://localhost:5678
- **Username**: `admin`
- **Password**: `please-change-me` (change this in production!)
- **API Endpoint**: http://localhost:5678/api/v1/
- **API Token**: `cli-dev-token`

### Stopping n8n

#### Windows (PowerShell)
```powershell
.\scripts\stop-n8n.ps1
```

#### Cross-platform (Docker Compose)
```bash
docker-compose down
```

## Usage

### Installing Community Packages

1. Access the n8n web interface
2. Go to **Settings** > **Community nodes**
3. Install packages like `n8n-nodes-mcp` for MCP integration

### API Access

Use the configured API token for programmatic access:

```bash
curl -H "Authorization: Bearer cli-dev-token" \
     http://localhost:5678/api/v1/workflows
```

### Development Workflow

1. Start n8n using the provided scripts
2. Create and test workflows in the web interface
3. Export workflows for version control
4. Use API for automated deployment

## Security Considerations

### Production Deployment

For production use, ensure you:

1. **Change default credentials**: Update `N8N_BASIC_AUTH_PASSWORD`
2. **Secure API tokens**: Use strong, unique tokens
3. **Enable HTTPS**: Configure SSL/TLS certificates
4. **Network security**: Use proper firewall rules
5. **Update regularly**: Keep n8n image updated

### Development Security

Even in development:

- Don't commit sensitive credentials to version control
- Use environment variables for sensitive data
- Regularly update the Docker image
- Monitor for security advisories

## Troubleshooting

### Common Issues

#### Docker not running
```
✗ Docker is not running. Please start Docker Desktop first.
```
**Solution**: Start Docker Desktop and wait for it to be ready.

#### Port already in use
```
Error: Port 5678 is already in use
```
**Solution**: Stop other services using port 5678 or change the port in `docker-compose.yml`.

#### Permission denied
```
Permission denied accessing Docker
```
**Solution**: Ensure your user is in the `docker` group (Linux) or Docker Desktop is running (Windows/macOS).

### Logs and Debugging

View n8n logs:
```bash
docker-compose logs -f n8n
```

Access the container:
```bash
docker-compose exec n8n sh
```

## Advanced Configuration

### Custom Environment File

Create a `.env` file for environment-specific configuration:

```env
N8N_BASIC_AUTH_PASSWORD=your-secure-password
N8N_PERSONAL_ACCESS_TOKENS_TOKENS_0_VALUE=your-secure-token
```

### Volume Mounting

For development, you can mount local directories:

```yaml
volumes:
  - ./n8n-data:/home/node/.n8n
  - ./custom-nodes:/home/node/.n8n/custom
```

### Network Configuration

For advanced networking (connecting to other services):

```yaml
networks:
  n8n-network:
    driver: bridge
```

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Docker Hub](https://hub.docker.com/r/n8nio/n8n)
- [Community Packages](https://www.npmjs.com/search?q=n8n-nodes)
- [n8n API Documentation](https://docs.n8n.io/api/)
