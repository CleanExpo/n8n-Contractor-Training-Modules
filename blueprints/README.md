# Workflow Blueprints

This directory contains reusable workflow templates and blueprints for common automation patterns.

## Structure

```
blueprints/
├── README.md                    # This file
├── basic/                       # Basic workflow patterns
│   ├── http-request.json       # Simple HTTP request template
│   ├── scheduler.json          # Cron/schedule template
│   └── webhook-response.json   # Webhook handler template
├── integrations/               # Third-party integrations
│   ├── github/                 # GitHub integration patterns
│   ├── slack/                  # Slack integration patterns
│   └── email/                  # Email automation patterns
├── data-processing/            # Data transformation workflows
│   ├── csv-processor.json     # CSV processing template
│   ├── json-transform.json    # JSON transformation
│   └── database-sync.json     # Database synchronization
└── advanced/                   # Complex workflow patterns
    ├── error-handling.json     # Error handling patterns
    ├── parallel-processing.json # Parallel execution
    └── conditional-flow.json   # Conditional logic patterns
```

## Using Blueprints

### Deploy a Blueprint
```powershell
# Using the CLI method
.\scripts\workflows\apply-cli.ps1 -WorkflowFile .\blueprints\basic\http-request.json

# Using the wizard
.\scripts\wizard\deploy-blueprint.ps1
```

### Create from Blueprint
```powershell
# Copy and customize a blueprint
.\scripts\wizard\new-from-blueprint.ps1 -Template "http-request" -Name "MyCustomWorkflow"
```

## Blueprint Categories

### Basic Patterns
- **HTTP Request**: Simple API calls with authentication
- **Scheduler**: Time-based triggers (cron, intervals)
- **Webhook Response**: Receive and process webhooks

### Integrations
- **GitHub**: PR notifications, issue tracking, CI/CD triggers
- **Slack**: Messaging, alerts, interactive workflows
- **Email**: Send notifications, process inbox, attachments

### Data Processing
- **CSV Processor**: Import, transform, export CSV data
- **JSON Transform**: Parse, modify, restructure JSON
- **Database Sync**: Sync data between databases

### Advanced Patterns
- **Error Handling**: Retry logic, fallbacks, notifications
- **Parallel Processing**: Split and merge execution paths
- **Conditional Flow**: If/else logic, switch statements

## Creating New Blueprints

1. Start with existing workflow or create new
2. Remove sensitive data (credentials, URLs)
3. Add placeholder values with clear names
4. Document required setup in comments
5. Test blueprint deployment

## Blueprint Standards

- Use descriptive node names
- Include comments for configuration
- Provide example data where helpful
- Document required credentials
- Follow naming convention: `category-purpose.json`

---

*Last Updated: 2025-09-18*