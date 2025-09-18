# n8n-MCP Integration Setup

## Overview

This project includes n8n-MCP (Model Context Protocol) integration that allows AI assistants like Claude to interact directly with n8n workflows. The MCP server provides comprehensive access to n8n node documentation, workflow management, and automation capabilities.

## What is n8n-MCP?

n8n-MCP is a bridge between n8n's workflow automation platform and AI models, enabling them to:

- 📚 Access 535+ n8n nodes documentation
- 🔧 Get node properties and configuration details
- ⚡ Understand node operations and capabilities
- 🤖 Validate workflow configurations
- 📄 Create and manage workflows programmatically

## Architecture

```
Claude Desktop / AI Tools
        ↓
   MCP Protocol
        ↓
   n8n-MCP Server (HTTP Mode)
        ↓
   n8n API (REST)
        ↓
   n8n Instance
```

## Getting Started

### Prerequisites

- Docker Desktop running
- n8n instance with API access enabled
- Claude Desktop or compatible AI tool

### 1. Start the Services

```powershell
# Start both n8n and n8n-mcp
.\scripts\start-n8n.ps1
```

This will start:
- **n8n**: http://localhost:5678
- **n8n-MCP**: http://localhost:3003

### 2. Verify Services

Check that both services are running:

```powershell
# Check n8n
curl http://localhost:5678/healthz

# Check n8n-MCP
curl http://localhost:3003/health
```

## Claude Desktop Configuration

### Option 1: npx (Recommended)

Add this to your Claude Desktop configuration:

**Location**: 
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

**Basic Configuration** (Documentation tools only):
```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["n8n-mcp"],
      "env": {
        "MCP_MODE": "stdio",
        "LOG_LEVEL": "error",
        "DISABLE_CONSOLE_OUTPUT": "true"
      }
    }
  }
}
```

**Full Configuration** (With n8n management):
```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["n8n-mcp"],
      "env": {
        "MCP_MODE": "stdio",
        "LOG_LEVEL": "error",
        "DISABLE_CONSOLE_OUTPUT": "true",
        "N8N_API_URL": "http://localhost:5678",
        "N8N_API_KEY": "cli-dev-token"
      }
    }
  }
}
```

### Option 2: Local HTTP Server

If you prefer to use the local HTTP server (port 3003):

```json
{
  "mcpServers": {
    "n8n-mcp-local": {
      "command": "node",
      "args": ["-e", "require('http').request('http://localhost:3003/mcp', {method:'POST'}).end()"],
      "env": {
        "MCP_MODE": "stdio",
        "LOG_LEVEL": "error"
      }
    }
  }
}
```

## Available MCP Tools

Once configured, Claude can use these powerful tools:

### Core Documentation Tools
- `tools_documentation` - Get documentation for any MCP tool
- `list_nodes` - List all n8n nodes with filtering options
- `get_node_info` - Get comprehensive node information
- `get_node_essentials` - Get essential properties (10-20 instead of 200+)
- `search_nodes` - Full-text search across node documentation
- `list_ai_tools` - List all AI-capable nodes

### Template Tools
- `list_templates` - Browse 2,500+ workflow templates
- `search_templates` - Search templates by name/description
- `get_template` - Get complete workflow JSON
- `get_templates_for_task` - Curated templates for common tasks

### Validation Tools
- `validate_node_operation` - Validate node configurations
- `validate_workflow` - Complete workflow validation
- `validate_workflow_connections` - Check workflow structure

### n8n Management Tools (if API configured)
- `n8n_create_workflow` - Create new workflows
- `n8n_get_workflow` - Get workflow by ID
- `n8n_update_workflow` - Update existing workflows
- `n8n_list_workflows` - List all workflows
- `n8n_trigger_workflow` - Execute workflows

## Example Usage with Claude

### 1. Getting Started
```
Can you help me understand what n8n nodes are available for sending emails?
```

Claude will use `search_nodes({query: "send email"})` to find relevant nodes.

### 2. Building a Workflow
```
Create a workflow that sends a Slack message when a webhook is received.
```

Claude will:
1. Use `get_node_essentials` for webhook and Slack nodes
2. Validate configurations with `validate_node_operation`
3. Build and validate the complete workflow
4. Create it in n8n using `n8n_create_workflow`

### 3. Finding Templates
```
Show me templates for processing webhook data and sending notifications.
```

Claude will use `search_templates` and `get_templates_for_task` to find relevant examples.

## Configuration Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MCP_MODE` | Protocol mode (stdio/http) | stdio |
| `LOG_LEVEL` | Logging level | error |
| `N8N_API_URL` | n8n instance URL | http://n8n:5678 |
| `N8N_API_KEY` | n8n API token | cli-dev-token |
| `PORT` | HTTP server port | 3001 |

### Docker Service Configuration

The `docker-compose.yml` includes:

```yaml
n8n-mcp:
  image: ghcr.io/czlonkowski/n8n-mcp:latest
  ports:
    - "3001:3001"
  environment:
    - MCP_MODE=http
    - N8N_API_URL=http://n8n:5678
    - N8N_API_KEY=cli-dev-token
  depends_on:
    - n8n
```

## Troubleshooting

### Common Issues

#### MCP Server Not Responding
```bash
# Check if container is running
docker-compose ps

# Check logs
docker-compose logs n8n-mcp
```

#### Claude Can't Connect
1. Restart Claude Desktop after configuration changes
2. Verify JSON syntax in configuration file
3. Check that ports 3001 and 5678 are accessible

#### n8n API Access Issues
```bash
# Test API connectivity
curl -H "Authorization: Bearer cli-dev-token" http://localhost:5678/api/v1/workflows
```

### Logs and Debugging

View n8n-MCP logs:
```bash
docker-compose logs -f n8n-mcp
```

View n8n logs:
```bash
docker-compose logs -f n8n
```

## Security Considerations

### Development Environment
- Default credentials are for development only
- API tokens are exposed in environment variables
- No HTTPS configured by default

### Production Deployment
For production use:
1. Change default passwords and API tokens
2. Enable HTTPS/SSL
3. Use proper secret management
4. Configure network security
5. Regular security updates

## Integration with Other AI Tools

### Claude Code
```bash
# Add MCP server configuration
claude code config add-mcp n8n-mcp npx n8n-mcp
```

### Visual Studio Code
Use the MCP extension and configure the server endpoint.

### Cursor
Add to your Cursor configuration following the MCP setup guide.

## Advanced Usage

### Custom Profiles
n8n-MCP supports validation profiles:
- `minimal` - Required fields only
- `runtime` - Full runtime validation
- `ai-friendly` - Optimized for AI assistance
- `strict` - Comprehensive validation

### Template Attribution
When using workflow templates, n8n-MCP automatically provides:
- Template author information
- Original template URL
- License information

## Performance

- **Average response time**: ~12ms
- **Database size**: ~15MB optimized SQLite
- **Node coverage**: 535/535 nodes (100%)
- **Documentation coverage**: 90%+

## Support

For issues with n8n-MCP integration:

1. Check the [n8n-MCP repository](https://github.com/czlonkowski/n8n-mcp)
2. Review Docker logs for error messages
3. Verify API connectivity between services
4. Ensure Claude Desktop configuration is correct

## Resources

- [n8n-MCP GitHub Repository](https://github.com/czlonkowski/n8n-mcp)
- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [Claude Desktop Configuration Guide](https://docs.anthropic.com/claude/docs/mcp)
- [n8n API Documentation](https://docs.n8n.io/api/)

---

**Next Steps**: Once configured, try asking Claude: "Can you show me what n8n tools are available?" to test the integration.
