# n8n API Setup Guide - Manual Configuration

## Current Situation

The n8n instance is running but API authentication is not working with the provided tokens. This is a common issue with n8n's API key system.

## Solution Options

### Option 1: Use n8n CLI (Recommended)
Instead of using the API directly, you can use the n8n CLI inside the container:

```bash
# Execute workflows directly in container
docker exec n8ncontractortrainingmodules-n8n-1 n8n execute --id <workflow-id>

# Import workflow
docker exec n8ncontractortrainingmodules-n8n-1 n8n import:workflow --input=/data/workflow.json

# List workflows
docker exec n8ncontractortrainingmodules-n8n-1 n8n list:workflow
```

### Option 2: Create API Key Through UI
1. Login to n8n UI at http://localhost:5678
2. Go to Settings → n8n API
3. Click "Create API Key"
4. **Important**: After creating, you may need to:
   - Logout and login again
   - Ensure the key shows as "Active"
   - Check if there's a "Scopes" or "Permissions" section

### Option 3: Use Cookie-Based Authentication
Since you can login through the UI, we can use session cookies:

```powershell
# Login and save cookie
$loginData = @{
    email = "your-email@example.com"
    password = "your-password"
}

$response = Invoke-WebRequest -Uri "http://localhost:5678/rest/login" `
    -Method POST `
    -Body ($loginData | ConvertTo-Json) `
    -ContentType "application/json" `
    -SessionVariable session

# Use session for API calls
$workflows = Invoke-RestMethod -Uri "http://localhost:5678/rest/workflows" `
    -WebSession $session
```

### Option 4: Direct Database Access
If API access continues to fail, you can interact with n8n's SQLite database directly:

```bash
# Access n8n database
docker exec -it n8ncontractortrainingmodules-n8n-1 sh
cd /home/node/.n8n
sqlite3 database.sqlite

# Query workflows
SELECT id, name, active FROM workflow_entity;
```

## Troubleshooting Steps

1. **Verify n8n Version**
   ```bash
   docker exec n8ncontractortrainingmodules-n8n-1 n8n --version
   ```

2. **Check API Settings in Database**
   ```bash
   docker exec n8ncontractortrainingmodules-n8n-1 sqlite3 /home/node/.n8n/database.sqlite \
     "SELECT * FROM settings WHERE key LIKE '%api%';"
   ```

3. **Enable Debug Logging**
   Add to docker-compose.yml:
   ```yaml
   environment:
     - N8N_LOG_LEVEL=debug
   ```

4. **Check for Required Environment Variables**
   Some versions need:
   ```yaml
   - N8N_PUBLIC_API_ENABLED=true
   - N8N_PUBLIC_API_SWAGGERUI_ENABLED=true
   ```

## Alternative: Use n8n's Internal API

The internal API (used by the UI) might work:

```javascript
// Get CSRF token first
fetch('http://localhost:5678/rest/csrf', {
    credentials: 'include'
}).then(r => r.json()).then(data => {
    // Use token for subsequent requests
    const csrfToken = data.token;

    // Make API call with CSRF token
    fetch('http://localhost:5678/rest/workflows', {
        headers: {
            'X-N8N-CSRF-Token': csrfToken
        },
        credentials: 'include'
    })
});
```

## Next Steps

1. Try the n8n CLI approach (Option 1) first
2. If you need programmatic access, try cookie-based auth (Option 3)
3. Consider upgrading/downgrading n8n version if API issues persist

## Notes

- API key functionality varies between n8n versions
- Some versions require additional configuration
- The UI always works because it uses session-based authentication
- Consider using webhooks as an alternative to direct API access

---

*Last Updated: 2025-09-18*