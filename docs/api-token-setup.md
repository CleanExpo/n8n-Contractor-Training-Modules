# n8n API Token Setup

## Important Note

n8n's Personal Access Tokens cannot be configured through environment variables at startup. They must be created through the UI after n8n is running.

## Steps to Create API Token

1. **Start n8n**
   ```bash
   docker-compose up -d
   ```

2. **Access n8n UI**
   - Open http://localhost:5678
   - Login with credentials:
     - Username: `admin`
     - Password: `please-change-me`

3. **Navigate to API Settings**
   - Click on your user icon (top right)
   - Select "Settings"
   - Go to "API" tab

4. **Create Personal Access Token**
   - Click "Add Personal Access Token"
   - Name: `cli-dev-token` (or any name you prefer)
   - Click "Create"
   - **IMPORTANT:** Copy the token immediately (it won't be shown again)

5. **Update Scripts**
   If your token differs from `cli-dev-token`, update it in:
   - `scripts/workflows/apply.ps1` (line 7)
   - `scripts/n8n-api.ps1` (line 3)
   - `scripts/smoke.ps1` (line 5)

## Alternative: Use API Key (If Available)

In newer versions of n8n, you might see an "API Keys" section:

1. Go to Settings → API Keys
2. Click "Generate API Key"
3. Copy the key and use it as the token

## Testing Your Token

```powershell
# Test with PowerShell
$headers = @{ "X-N8N-API-KEY" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2MDk1YzQzOS1hYWY5LTQwNDYtYTM4MS0wYzNmN2JhYzNlMDYiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzU4MTk3NTU2fQ.AdPVqmzQ8QtFcNoRqXC2GINIRWJ5xeDVsnEBqrJ11pA" }
Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows" -Headers $headers

# Test with curl
curl -H "X-N8N-API-KEY: your-token-here" http://localhost:5678/api/v1/workflows
```

## Troubleshooting

### Token Not Working

1. Ensure n8n is running: `docker-compose ps`
2. Check you copied the full token
3. Verify no extra spaces in token
4. Try regenerating a new token

### API Endpoint Returns 404

- Ensure public API is enabled in docker-compose.yml:
  ```yaml
  - N8N_PUBLIC_API_DISABLED=false
  ```

### Still Getting "Unauthorized"

- Double-check the header name is exactly `X-N8N-API-KEY`
- Token might have expired (regenerate in UI)
- Check n8n logs: `docker-compose logs n8n`

## Security Notes

- Never commit tokens to version control
- Use environment variables or secret management in production
- Rotate tokens regularly
- Use different tokens for different environments

---

*Last Updated: 2025-09-18*