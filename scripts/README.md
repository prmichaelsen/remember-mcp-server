# Utility Scripts

This directory contains TypeScript utility scripts for deployment, testing, and management.

## Running Scripts

### Direct Execution
```bash
npx tsx scripts/script-name.ts [args]
```

### Via npm Scripts
```bash
npm run script:upload-secrets
npm run script:upload-secrets -- --project my-project
```

## Available Scripts

### upload-secrets.ts

Uploads secrets from `.env` file to Google Cloud Secret Manager.

**Usage:**
```bash
# Use default project from gcloud config
npx tsx scripts/upload-secrets.ts

# Specify project
npx tsx scripts/upload-secrets.ts --project my-project-id

# Use different env file
npx tsx scripts/upload-secrets.ts --env-file .env.production
```

**Features:**
- Reads secrets from .env file
- Automatically converts variable names to secret names (e.g., `PLATFORM_SERVICE_TOKEN` → `platform-service-token`)
- Creates new secrets or updates existing ones
- Skips non-secret variables (NODE_ENV, PORT, LOG_LEVEL, PLATFORM_URL)
- Provides summary of uploaded secrets
- Shows Cloud Run deployment command with all secrets

**Example Output:**
```
Reading secrets from: .env

Found 1 secrets to upload:
  - PLATFORM_SERVICE_TOKEN: test-secre...

Uploading to project: my-project
────────────────────────────────────────────────────────────
🆕 Creating platform-service-token...
✅ Created platform-service-token
────────────────────────────────────────────────────────────

📊 Summary:
   ✅ Success: 1
   ❌ Failed: 0
   📦 Total: 1

💡 To use these secrets in Cloud Run:
   gcloud run deploy SERVICE_NAME \
     --update-secrets=PLATFORM_SERVICE_TOKEN=platform-service-token:latest \
```

## TypeScript Configuration

Scripts use `scripts/tsconfig.json` which:
- Extends main tsconfig.json
- Allows importing from src/ using @/ alias
- Includes both scripts/ and src/ directories
- Works with tsx for direct execution

## Accessing Project Code

Scripts can import from src:
```typescript
import { PlatformJWTProvider } from '@/auth/platform-jwt-provider.js';
import { PlatformTokenResolver } from '@/auth/platform-token-resolver.js';
```

## Requirements

- Google Cloud SDK (`gcloud`) installed and configured
- Authenticated with Google Cloud (`gcloud auth login`)
- Project set or specified via `--project` flag
- Appropriate permissions to create/update secrets
- tsx installed (included in devDependencies)

## Adding New Scripts

Scripts should:
1. Include shebang: `#!/usr/bin/env tsx` at top
2. Include usage documentation
3. Handle errors gracefully with try/catch
4. Provide clear output and progress indicators
5. Exit with appropriate exit codes (0 for success, 1 for error)
6. Use TypeScript for type safety
