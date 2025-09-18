# Developer Quickstart Guide

## Overview
Get up and running with n8n-MCP integration in 5 minutes. This guide provides the essential commands and workflows for immediate productivity.

## Prerequisites Checklist

- [ ] Docker Desktop installed and running
- [ ] PowerShell 5.1+ available
- [ ] Ports 5678 and 3003 free
- [ ] Claude Desktop installed

## 1. Quick Setup (2 minutes)

```powershell
# Clone and navigate to project
git clone <repository-url>
cd "n8n Contractor Training Modules"

# Start all services
docker-compose up -d

# Verify services are running
.\scripts\smoke.ps1
```

Expected output:
```
✓ n8n service is healthy
✓ n8n API authentication successful
✓ MCP service is healthy
✓ MCP API connectivity successful
```

## 2. Deploy First Workflow (1 minute)

```powershell
# Deploy example workflow
.\scripts\workflows\apply.ps1 -WorkflowFile flows\example.json -Activate

# Verify deployment
. .\scripts\n8n-api.ps1
Get-N8nWorkflows | Format-Table Name, Active, Id
```

## 3. Configure Claude Desktop (2 minutes)

1. Open Claude Desktop config:
   - **Windows:** `notepad %APPDATA%\Claude\claude_desktop_config.json`
   - **Mac:** `open ~/Library/Application Support/Claude/claude_desktop_config.json`

2. Add MCP configuration:
```json
{
  "mcpServers": {
    "n8n-mcp": {
      "url": "http://localhost:3003",
      "headers": {
        "Authorization": "Bearer mcp-dev-token"
      },
      "transport": "http"
    }
  }
}
```

3. Restart Claude Desktop

## Essential Commands

### Service Management

```powershell
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Restart services
docker-compose restart
```

### Workflow Operations

```powershell
# List workflows
. .\scripts\n8n-api.ps1
Get-N8nWorkflows

# Deploy workflow
.\scripts\workflows\apply.ps1 -WorkflowFile <path>

# Deploy and activate
.\scripts\workflows\apply.ps1 -WorkflowFile <path> -Activate

# Validate workflow
.\scripts\mcp-validate.ps1 -WorkflowFile <path>

# Export workflow
Export-N8nWorkflow -Id <workflow-id> -Path <output-path>

# Import workflow
Import-N8nWorkflow -Path <input-path> -Activate
```

### Health Checks

```powershell
# Full system check
.\scripts\smoke.ps1

# Test API connection
. .\scripts\n8n-api.ps1
Test-N8nConnection

# Check MCP
Invoke-WebRequest -Uri "http://localhost:3003/health"
```

## Common Workflows

### 1. Create and Deploy New Workflow

```powershell
# 1. Create workflow JSON
@{
    name = "My Workflow"
    nodes = @(
        @{
            id = "start"
            name = "Start"
            type = "n8n-nodes-base.start"
            position = @(250, 300)
        }
    )
    connections = @{}
} | ConvertTo-Json -Depth 10 | Out-File flows\my-workflow.json

# 2. Validate
.\scripts\mcp-validate.ps1 -WorkflowFile flows\my-workflow.json

# 3. Deploy
.\scripts\workflows\apply.ps1 -WorkflowFile flows\my-workflow.json -Activate
```

### 2. Update Existing Workflow

```powershell
# 1. Export current version
. .\scripts\n8n-api.ps1
Export-N8nWorkflow -Id "workflow-id" -Path flows\backup.json

# 2. Edit workflow
# (Make changes to the JSON file)

# 3. Apply updates
.\scripts\workflows\apply.ps1 -WorkflowFile flows\updated.json
```

### 3. Execute Workflow via API

```powershell
. .\scripts\n8n-api.ps1

# Manual execution
Start-N8nExecution -WorkflowId "workflow-id"

# With input data
$data = @{
    message = "Hello from PowerShell"
}
Start-N8nExecution -WorkflowId "workflow-id" -Data $data

# Check execution status
Get-N8nExecutions -WorkflowId "workflow-id" -Limit 5
```

## Claude Desktop Integration

Once MCP is configured, use these prompts in Claude:

### Workflow Management
- "Show me all n8n workflows"
- "Create a workflow that monitors GitHub and posts to Slack"
- "Help me debug workflow ID xyz"

### Node Information
- "What n8n nodes are available for HTTP requests?"
- "Show me how to use the Webhook node"
- "What parameters does the Slack node accept?"

### Execution Analysis
- "Show recent executions for my workflows"
- "Why did my last workflow execution fail?"
- "How can I optimize my workflow performance?"

## Quick Troubleshooting

### Services Won't Start

```powershell
# Check Docker
docker version

# Clean restart
docker-compose down -v
docker-compose up -d

# Check ports
netstat -an | findstr "5678 3003"
```

### API Authentication Fails

```powershell
# Test with curl
curl -H "X-N8N-API-KEY: cli-dev-token" http://localhost:5678/api/v1/workflows

# Update token in scripts
$env:N8N_API_TOKEN = "new-token"
```

### MCP Not Connecting

```powershell
# Check MCP health
Invoke-WebRequest -Uri "http://localhost:3003/health" -Headers @{"Authorization"="Bearer mcp-dev-token"}

# Restart MCP container
docker-compose restart n8n-mcp

# Check logs
docker-compose logs n8n-mcp --tail=50
```

## Project Structure

```
n8n Contractor Training Modules/
├── docker-compose.yml      # Service configuration
├── flows/                  # Workflow templates
│   ├── example.json
│   └── github-slack.json
├── scripts/               # PowerShell automation
│   ├── n8n-api.ps1       # API helper functions
│   ├── smoke.ps1         # Health checks
│   ├── mcp-validate.ps1  # Workflow validation
│   └── workflows/
│       └── apply.ps1     # Deployment script
└── docs/                 # Documentation
    ├── quickstart.md     # This file
    ├── n8n-setup.md      # Detailed setup
    └── mcp-setup.md      # MCP configuration
```

## Next Steps

**After completing quickstart:**

1. **Explore Templates:** Review `flows/` directory
2. **Customize Workflows:** Create your own JSON definitions
3. **Extend API Scripts:** Add custom functions to `n8n-api.ps1`
4. **Production Setup:** Review security settings in documentation

## Useful Resources

- [n8n Node Documentation](https://docs.n8n.io/nodes/)
- [n8n API Reference](https://docs.n8n.io/api/)
- [MCP Specification](https://github.com/czlonkowski/n8n-mcp)
- [PowerShell Documentation](https://docs.microsoft.com/powershell/)

## Support

- **Issues:** Check `docs/troubleshooting.md`
- **Updates:** Pull latest changes with `git pull`
- **Community:** n8n Forum and GitHub Discussions

---

*Get productive in 5 minutes, master in 5 days!*

*Last Updated: 2025-09-18*