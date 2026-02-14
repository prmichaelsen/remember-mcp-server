# Bootstrap Pattern: Multi-Tenant MCP Server with Platform JWT Auth

## Overview

This document describes how to replicate the multi-tenant MCP server pattern for **any MCP server** that you want to make multi-tenant with Platform JWT authentication.

There are **two implementation patterns**:

1. **Dynamic Pattern** (with tokenResolver) - For servers that need OAuth tokens from external APIs
2. **Static Pattern** (no tokenResolver) - For servers with static credentials or self-contained storage

## Pattern Selection Guide

### Use Static Pattern (No TokenResolver) When:

✅ Server manages its own storage (database, vector store, etc.)  
✅ Credentials are static environment variables (API keys, connection strings)  
✅ No per-user OAuth tokens needed  
✅ Examples: remember-mcp, note-taking servers, internal tools

**Implementation**: Only requires `authProvider`, no `tokenResolver`

### Use Dynamic Pattern (With TokenResolver) When:

✅ Server needs per-user OAuth tokens from external APIs  
✅ Users connect their own accounts (GitHub, Slack, Instagram, etc.)  
✅ Tokens are stored in platform database  
✅ Examples: github-mcp, slack-mcp, instagram-mcp

**Implementation**: Requires both `authProvider` and `tokenResolver`

---

## Static Pattern Implementation (remember-mcp Example)

This is the **simpler pattern** for servers that don't need per-user OAuth tokens.

### Prerequisites

Your base MCP server must export a **server factory function**:

```typescript
export function createYourServer(
  accessToken: string,  // Can be empty string for static servers
  userId: string,
  options?: ServerOptions
): Server | Promise<Server>
```

This factory should:
- Accept a userId for per-user isolation
- Return a configured MCP `Server` instance
- Register all tools internally
- **Tool Naming**: Tools must be named `{resourceType}_{tool_name}` (e.g., `remember_store`)

### Step 1: Create New Multi-Tenant Server Project

```bash
mkdir your-mcp-server
cd your-mcp-server
npm init -y
```

### Step 2: Install Dependencies

```bash
npm install \
  @modelcontextprotocol/sdk \
  @prmichaelsen/mcp-auth \
  @your-org/your-mcp-base \
  jsonwebtoken

npm install --save-dev \
  typescript \
  @types/node \
  @types/jsonwebtoken \
  tsx
```

### Step 3: Create Project Structure

```
your-mcp-server/
├── src/
│   ├── index.ts                    # Main server
│   └── auth/
│       └── platform-jwt-provider.ts    # Platform JWT validation
├── agent/                          # Agent Context Protocol docs
├── scripts/                        # Utility scripts
│   ├── README.md
│   └── upload-secrets.ts          # Secret management
├── package.json
├── tsconfig.json
├── Dockerfile
├── cloudbuild.yaml
├── .env.example
├── .gitignore
└── README.md
```

**Note**: No `platform-token-resolver.ts` needed for static pattern!

### Step 4: Configure package.json

```json
{
  "name": "@your-org/your-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "dev": "tsx watch src/index.ts",
    "start": "node dist/index.js",
    "type-check": "tsc --noEmit",
    "script": "tsx",
    "script:upload-secrets": "tsx scripts/upload-secrets.ts"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4",
    "@prmichaelsen/mcp-auth": "^7.0.3",
    "@your-org/your-mcp-base": "^1.0.0",
    "jsonwebtoken": "^9.0.2"
  },
  "devDependencies": {
    "@types/node": "^22.10.2",
    "@types/jsonwebtoken": "^9.0.5",
    "tsx": "^4.7.0",
    "typescript": "^5.7.2"
  }
}
```

### Step 5: Configure TypeScript

**tsconfig.json**:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "lib": ["ES2022"],
    "moduleResolution": "bundler",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true,
    "sourceMap": true,
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Step 6: Create Platform JWT Auth Provider

**src/auth/platform-jwt-provider.ts**:

```typescript
import type { AuthProvider, AuthResult, RequestContext } from '@prmichaelsen/mcp-auth';
import jwt from 'jsonwebtoken';

export interface PlatformJWTProviderConfig {
  serviceToken: string;
  issuer: string;
  audience: string;
  cacheResults?: boolean;
  cacheTtl?: number;
}

interface CachedAuthResult {
  result: AuthResult;
  expiresAt: number;
}

export class PlatformJWTProvider implements AuthProvider {
  private config: PlatformJWTProviderConfig;
  private authCache = new Map<string, CachedAuthResult>();
  
  constructor(config: PlatformJWTProviderConfig) {
    this.config = config;
  }
  
  async initialize(): Promise<void> {
    console.log('Platform JWT auth provider initialized');
  }
  
  async authenticate(context: RequestContext): Promise<AuthResult> {
    try {
      const authHeader = context.headers?.['authorization'];
      
      if (!authHeader || Array.isArray(authHeader)) {
        return { authenticated: false, error: 'No authorization header' };
      }
      
      const parts = authHeader.split(' ');
      if (parts.length !== 2 || parts[0] !== 'Bearer') {
        return { authenticated: false, error: 'Invalid authorization format' };
      }
      
      const token = parts[1];
      
      // Check cache
      if (this.config.cacheResults) {
        const cached = this.authCache.get(token);
        if (cached && Date.now() < cached.expiresAt) {
          return cached.result;
        }
      }
      
      // Verify JWT
      const decoded = jwt.verify(token, this.config.serviceToken, {
        issuer: this.config.issuer,
        audience: this.config.audience
      }) as { userId: string; email?: string };
      
      const result: AuthResult = {
        authenticated: true,
        userId: decoded.userId,
        metadata: {
          email: decoded.email
        }
      };
      
      // Cache result
      if (this.config.cacheResults) {
        const ttl = this.config.cacheTtl || 60000;
        this.authCache.set(token, {
          result,
          expiresAt: Date.now() + ttl
        });
      }
      
      return result;
    } catch (error) {
      return {
        authenticated: false,
        error: error instanceof Error ? error.message : 'Authentication failed'
      };
    }
  }
  
  async cleanup(): Promise<void> {
    this.authCache.clear();
  }
}
```

### Step 7: Create Main Server (Static Pattern)

**src/index.ts**:

```typescript
#!/usr/bin/env node

import { wrapServer } from '@prmichaelsen/mcp-auth';
import { createServer as createYourServer } from '@your-org/your-mcp-base/factory';
import { PlatformJWTProvider } from './auth/platform-jwt-provider.js';

// Configuration
const config = {
  platform: {
    url: process.env.PLATFORM_URL!,
    serviceToken: process.env.PLATFORM_SERVICE_TOKEN!
  },
  server: {
    port: parseInt(process.env.PORT || '8080')
  }
};

// Validate required configuration
if (!config.platform.serviceToken) {
  console.error('Error: PLATFORM_SERVICE_TOKEN environment variable is required');
  process.exit(1);
}

if (!config.platform.url) {
  console.error('Error: PLATFORM_URL environment variable is required');
  process.exit(1);
}

// Create auth provider
const authProvider = new PlatformJWTProvider({
  serviceToken: config.platform.serviceToken,
  issuer: 'agentbase.me',
  audience: 'mcp-server',
  cacheResults: true,
  cacheTtl: 60000 // 60 seconds
});

// Wrap server with authentication (NO tokenResolver for static pattern)
const wrappedServer = wrapServer({
  serverFactory: async (accessToken: string, userId: string) => {
    // For static servers, accessToken is empty string
    // Server uses environment variables for credentials
    return await createYourServer(accessToken, userId);
  },
  authProvider,
  // NO tokenResolver - static pattern!
  resourceType: 'your-resource-type', // e.g., 'remember', 'notes', etc.
  transport: {
    type: 'sse',
    port: config.server.port,
    host: '0.0.0.0',
    basePath: '/mcp',
    cors: true,
    corsOrigin: process.env.CORS_ORIGIN || 'https://agentbase.me'
  },
  middleware: {
    rateLimit: {
      enabled: true,
      maxRequests: 100,
      windowMs: 60 * 60 * 1000 // 1 hour
    },
    logging: {
      enabled: true,
      level: 'info'
    }
  }
});

// Start server
async function main() {
  try {
    await wrappedServer.start();
    console.log(`✅ Server started successfully`);
    console.log(`📡 Listening on port ${config.server.port}`);
    console.log(`🔗 Endpoint: http://0.0.0.0:${config.server.port}/mcp`);
    console.log(`🏥 Health check: http://0.0.0.0:${config.server.port}/mcp/health`);
    console.log(`🔐 Authentication: Platform JWT (agentbase.me)`);
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  await wrappedServer.stop();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  await wrappedServer.stop();
  process.exit(0);
});

// Start the server
main();
```

**Key Differences from Dynamic Pattern**:
- ❌ No `PlatformTokenResolver` import
- ❌ No `tokenResolver` in `wrapServer()` config
- ✅ Server uses environment variables for credentials
- ✅ `accessToken` parameter is empty string (unused)
- ✅ Simpler implementation

### Step 8: Create Environment Template

**.env.example**:

```env
# Platform JWT (shared secret for JWT validation)
PLATFORM_SERVICE_TOKEN=your-shared-secret

# Platform API (for health checks, not credentials)
PLATFORM_URL=https://agentbase.me

# CORS Configuration
CORS_ORIGIN=https://agentbase.me

# Server Configuration
PORT=8080
NODE_ENV=development
LOG_LEVEL=info

# Your Service Credentials (static, not per-user)
# Example for remember-mcp:
WEAVIATE_REST_URL=https://your-weaviate.weaviate.network
WEAVIATE_GRPC_URL=grpc://your-weaviate.weaviate.network:443
WEAVIATE_API_KEY=your-api-key
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_ADMIN_SERVICE_ACCOUNT_KEY={"type":"service_account",...}
OPENAI_EMBEDDINGS_API_KEY=sk-...
EMBEDDINGS_PROVIDER=openai
EMBEDDINGS_MODEL=text-embedding-3-small
```

### Step 9: Create Dockerfile

**Dockerfile**:

```dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY src ./src

# Build TypeScript
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Clear npm cache and install production dependencies only
RUN npm cache clean --force && npm ci --omit=dev

# Copy built files from builder
COPY --from=builder /app/dist ./dist

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://localhost:8080/mcp/health').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

# Start server
CMD ["node", "dist/index.js"]
```

### Step 10: Create Cloud Build Configuration

**cloudbuild.yaml**:

```yaml
steps:
  # Build Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'gcr.io/$PROJECT_ID/your-mcp-server:$COMMIT_SHA'
      - '-t'
      - 'gcr.io/$PROJECT_ID/your-mcp-server:latest'
      - '.'
  
  # Push to Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'push'
      - 'gcr.io/$PROJECT_ID/your-mcp-server:$COMMIT_SHA'
  
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'push'
      - 'gcr.io/$PROJECT_ID/your-mcp-server:latest'
  
  # Deploy to Cloud Run
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      - 'run'
      - 'deploy'
      - 'your-mcp-server'
      - '--image=gcr.io/$PROJECT_ID/your-mcp-server:$COMMIT_SHA'
      - '--platform=managed'
      - '--region=us-central1'
      - '--allow-unauthenticated'
      - '--min-instances=0'
      - '--max-instances=10'
      - '--memory=512Mi'
      - '--cpu=1'
      - '--timeout=60s'
      - '--set-env-vars=NODE_ENV=production,PLATFORM_URL=https://agentbase.me'
      - '--update-secrets=PLATFORM_SERVICE_TOKEN=your-platform-service-token:latest,CORS_ORIGIN=your-cors-origin:latest,YOUR_API_KEY=your-api-key:latest'

images:
  - 'gcr.io/$PROJECT_ID/your-mcp-server:$COMMIT_SHA'
  - 'gcr.io/$PROJECT_ID/your-mcp-server:latest'

options:
  machineType: 'E2_HIGHCPU_8'
  logging: CLOUD_LOGGING_ONLY
```

### Step 11: Create Secret Upload Script

**scripts/upload-secrets.ts**:

```typescript
#!/usr/bin/env tsx

/**
 * Upload secrets from .env to Google Cloud Secret Manager
 *
 * Usage: npx tsx scripts/upload-secrets.ts --service SERVICE_NAME [--project PROJECT_ID] [--env-file .env]
 */

import { readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

// Parse command line arguments
const args = process.argv.slice(2);
let projectId: string | null = null;
let envFile = '.env';
let serviceName: string | null = null;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--service' && args[i + 1]) {
    serviceName = args[i + 1];
    i++;
  } else if (args[i] === '--project' && args[i + 1]) {
    projectId = args[i + 1];
    i++;
  } else if (args[i] === '--env-file' && args[i + 1]) {
    envFile = args[i + 1];
    i++;
  }
}

// Validate required arguments
if (!serviceName) {
  console.error('Error: --service flag is required');
  console.error('Usage: npx tsx scripts/upload-secrets.ts --service SERVICE_NAME [--project PROJECT_ID] [--env-file .env]');
  console.error('Example: npx tsx scripts/upload-secrets.ts --service remember');
  process.exit(1);
}

// Get project ID from gcloud if not provided
if (!projectId) {
  try {
    projectId = execSync('gcloud config get-value project', { encoding: 'utf-8' }).trim();
    console.log(`Using project from gcloud config: ${projectId}`);
  } catch (error) {
    console.error('Error: Could not determine project ID');
    console.error('Please specify with --project flag or set default project with: gcloud config set project PROJECT_ID');
    process.exit(1);
  }
}

// Variables to skip (not secrets)
const SKIP_VARS = new Set([
  'NODE_ENV',
  'PORT',
  'LOG_LEVEL',
  'PLATFORM_URL'  // Public URL, not a secret
]);

// Read and parse .env file
console.log(`\nReading secrets from: ${envFile}`);
let envContent: string;
try {
  envContent = readFileSync(envFile, 'utf-8');
} catch (error) {
  console.error(`Error: Could not read ${envFile}`);
  console.error((error as Error).message);
  process.exit(1);
}

// Parse environment variables
const secrets: Record<string, string> = {};
const lines = envContent.split('\n');

for (const line of lines) {
  const trimmed = line.trim();
  
  // Skip empty lines and comments
  if (!trimmed || trimmed.startsWith('#')) {
    continue;
  }
  
  // Parse KEY=VALUE
  const match = trimmed.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
  if (match) {
    const [, key, value] = match;
    
    // Skip non-secret variables
    if (SKIP_VARS.has(key)) {
      console.log(`⏭️  Skipping ${key} (not a secret)`);
      continue;
    }
    
    // Remove quotes if present
    let cleanValue = value.trim();
    if ((cleanValue.startsWith('"') && cleanValue.endsWith('"')) ||
        (cleanValue.startsWith("'") && cleanValue.endsWith("'"))) {
      cleanValue = cleanValue.slice(1, -1);
    }
    
    if (cleanValue) {
      secrets[key] = cleanValue;
    }
  }
}

if (Object.keys(secrets).length === 0) {
  console.log('\n⚠️  No secrets found to upload');
  process.exit(0);
}

console.log(`\nFound ${Object.keys(secrets).length} secrets to upload`);
console.log(`Uploading to project: ${projectId}`);
console.log('─'.repeat(60));

// Upload each secret
let successCount = 0;
let errorCount = 0;

for (const [key, value] of Object.entries(secrets)) {
  // Prefix secret name with service name to avoid conflicts
  const secretName = `${serviceName}-${key.toLowerCase().replace(/_/g, '-')}`;
  
  try {
    // Check if secret exists
    let secretExists = false;
    try {
      execSync(`gcloud secrets describe ${secretName} --project=${projectId}`, { 
        stdio: 'pipe',
        encoding: 'utf-8'
      });
      secretExists = true;
    } catch {
      // Secret doesn't exist, will create it
    }
    
    // Write value to temp file to avoid shell escaping issues
    const tempFile = join(tmpdir(), `secret-${Date.now()}.txt`);
    try {
      writeFileSync(tempFile, value, 'utf-8');
      
      if (secretExists) {
        // Add new version to existing secret
        console.log(`📝 Updating ${secretName}...`);
        execSync(`gcloud secrets versions add ${secretName} --data-file=${tempFile} --project=${projectId}`, {
          stdio: 'pipe'
        });
        console.log(`✅ Updated ${secretName}`);
      } else {
        // Create new secret
        console.log(`🆕 Creating ${secretName}...`);
        execSync(`gcloud secrets create ${secretName} --data-file=${tempFile} --project=${projectId}`, {
          stdio: 'pipe'
        });
        console.log(`✅ Created ${secretName}`);
      }
    } finally {
      // Clean up temp file
      try {
        unlinkSync(tempFile);
      } catch {}
    }
    
    successCount++;
  } catch (error) {
    console.error(`❌ Failed to upload ${secretName}`);
    console.error(`   ${(error as Error).message}`);
    errorCount++;
  }
}

console.log('─'.repeat(60));
console.log(`\n📊 Summary:`);
console.log(`   ✅ Success: ${successCount}`);
console.log(`   ❌ Failed: ${errorCount}`);
console.log(`   📦 Total: ${Object.keys(secrets).length}`);

if (successCount > 0) {
  console.log(`\n💡 Secret names for Cloud Run deployment:`);
  Object.keys(secrets).forEach(key => {
    const secretName = `${serviceName}-${key.toLowerCase().replace(/_/g, '-')}`;
    console.log(`   ${key}=${secretName}:latest`);
  });
}

process.exit(errorCount > 0 ? 1 : 0);
```

**scripts/README.md**:

```markdown
# Utility Scripts

This directory contains TypeScript utility scripts for deployment and management.

## Available Scripts

### upload-secrets.ts

Uploads secrets from `.env` file to Google Cloud Secret Manager with service-specific prefixes.

**Usage:**
\`\`\`bash
# Upload secrets with service prefix
npx tsx scripts/upload-secrets.ts --service remember

# Specify project
npx tsx scripts/upload-secrets.ts --service remember --project my-project-id

# Use different env file
npx tsx scripts/upload-secrets.ts --service remember --env-file .env.production
\`\`\`

**Features:**
- Prefixes secret names with service name (e.g., `remember-weaviate-api-key`)
- Skips non-secret variables (NODE_ENV, PORT, PLATFORM_URL)
- Creates or updates secrets automatically
- Provides Cloud Run deployment command with all secrets

## Requirements

- Google Cloud SDK (`gcloud`) installed and configured
- Authenticated with Google Cloud (`gcloud auth login`)
- Appropriate permissions to create/update secrets
```

---

## Dynamic Pattern Implementation (OAuth Tokens)

For servers that need per-user OAuth tokens, add the `PlatformTokenResolver`:

### Additional File: src/auth/platform-token-resolver.ts

```typescript
import type {
  ResourceTokenResolver,
  CredentialsAPIResponse,
  CredentialsAPIHeaders,
  TenantAPIErrorResponse
} from '@prmichaelsen/mcp-auth';
import type { PlatformJWTProvider } from './platform-jwt-provider.js';

export interface PlatformTokenResolverConfig {
  platformUrl: string;
  authProvider: PlatformJWTProvider;
  cacheTokens?: boolean;
  cacheTtl?: number;
}

interface CachedToken {
  token: string;
  expiresAt: number;
}

export class PlatformTokenResolver implements ResourceTokenResolver {
  private config: PlatformTokenResolverConfig;
  private tokenCache = new Map<string, CachedToken>();
  
  constructor(config: PlatformTokenResolverConfig) {
    this.config = config;
  }
  
  async initialize(): Promise<void> {
    console.log('Platform token resolver initialized');
  }
  
  async resolveToken(userId: string, resourceType: string): Promise<string | null> {
    try {
      const cacheKey = `${userId}:${resourceType}`;
      
      // Check cache
      if (this.config.cacheTokens !== false) {
        const cached = this.tokenCache.get(cacheKey);
        if (cached && Date.now() < cached.expiresAt) {
          return cached.token;
        }
      }
      
      // Get JWT token from auth provider
      const jwtToken = this.config.authProvider.getJWTToken(userId);
      if (!jwtToken) {
        console.warn(`No JWT token found for user ${userId}`);
        return null;
      }
      
      // Call platform API with JWT
      const url = `${this.config.platformUrl}/api/credentials/${resourceType}`;
      const headers: CredentialsAPIHeaders = {
        'Authorization': `Bearer ${jwtToken}`,
        'X-User-ID': userId
      };
      
      const response = await fetch(url, {
        headers: {
          ...headers,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        const errorData = await response.json() as TenantAPIErrorResponse;
        
        if (response.status === 404) {
          console.warn(`No ${resourceType} credentials for user ${userId}`);
          return null;
        }
        
        console.error('Platform API error:', errorData);
        throw new Error(`Platform API error: ${errorData.error || response.status}`);
      }
      
      const data = await response.json() as CredentialsAPIResponse;
      const token = data.access_token;
      
      if (!token) {
        console.warn('Token field missing');
        return null;
      }
      
      // Cache token
      if (this.config.cacheTokens !== false) {
        const ttl = this.config.cacheTtl || 300000;
        this.tokenCache.set(cacheKey, {
          token,
          expiresAt: Date.now() + ttl
        });
      }
      
      return token;
    } catch (error) {
      console.error('Failed to resolve token:', error);
      return null;
    }
  }
  
  async cleanup(): Promise<void> {
    this.tokenCache.clear();
  }
}
```

### Modified Main Server (Dynamic Pattern)

```typescript
#!/usr/bin/env node

import { wrapServer } from '@prmichaelsen/mcp-auth';
import { createServer as createYourServer } from '@your-org/your-mcp-base/factory';
import { PlatformJWTProvider } from './auth/platform-jwt-provider.js';
import { PlatformTokenResolver } from './auth/platform-token-resolver.js';

// ... config and validation ...

// Create auth provider
const authProvider = new PlatformJWTProvider({
  serviceToken: config.platform.serviceToken,
  issuer: 'agentbase.me',
  audience: 'mcp-server',
  cacheResults: true,
  cacheTtl: 60000
});

// Create token resolver (DYNAMIC PATTERN)
const tokenResolver = new PlatformTokenResolver({
  platformUrl: config.platform.url,
  authProvider: authProvider,
  cacheTokens: true,
  cacheTtl: 300000
});

// Wrap server with authentication AND token resolution
const wrappedServer = wrapServer({
  serverFactory: async (accessToken: string, userId: string) => {
    // accessToken is fetched from platform API per-user
    return await createYourServer(accessToken, userId);
  },
  authProvider,
  tokenResolver,  // ADD tokenResolver for dynamic pattern
  resourceType: 'github', // Must match credentials API endpoint
  transport: {
    type: 'sse',
    port: config.server.port,
    host: '0.0.0.0',
    basePath: '/mcp',
    cors: true,
    corsOrigin: process.env.CORS_ORIGIN || 'https://agentbase.me'
  },
  middleware: {
    rateLimit: {
      enabled: true,
      maxRequests: 100,
      windowMs: 60 * 60 * 1000
    },
    logging: {
      enabled: true,
      level: 'info'
    }
  }
});

// ... rest of server startup ...
```

---

## Base MCP Server Requirements

### For Static Pattern

```typescript
// your-mcp-base/src/server-factory.ts

import { Server } from '@modelcontextprotocol/sdk/server/index.js';

export async function createYourServer(
  accessToken: string,  // Empty string for static servers
  userId: string,
  options?: ServerOptions
): Promise<Server> {
  // Initialize with environment variables
  const apiKey = process.env.YOUR_API_KEY!;
  const dbUrl = process.env.DATABASE_URL!;
  
  // Create per-user isolated storage
  const storage = new UserStorage(userId, dbUrl);
  await storage.initialize();
  
  // Create MCP server
  const server = new Server({
    name: 'your-server',
    version: '1.0.0'
  }, {
    capabilities: { tools: {} }
  });
  
  // Register tools with {resourceType}_ prefix
  server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
      tools: [
        { name: 'yourservice_store', description: '...', inputSchema: {...} },
        { name: 'yourservice_recall', description: '...', inputSchema: {...} },
      ]
    };
  });
  
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    
    switch (name) {
      case 'yourservice_store':
        // Use storage with userId isolation
        await storage.store(args.data);
        break;
      case 'yourservice_recall':
        return await storage.recall(args.query);
    }
  });
  
  return server;
}
```

### For Dynamic Pattern

```typescript
export async function createYourServer(
  accessToken: string,  // OAuth token from platform
  userId: string,
  options?:
