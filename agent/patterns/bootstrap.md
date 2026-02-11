# Bootstrap Pattern: Multi-Tenant MCP Server with Platform JWT Auth

## Overview

This document describes how to replicate the agentbase-mcp-server pattern for **any MCP server** that you want to make multi-tenant with Platform JWT authentication.

## Prerequisites

Your base MCP server must export a **server factory function**:

```typescript
export function createYourServer(
  accessToken: string,
  userId: string,
  options?: ServerOptions
): Server
```

This factory should:
- Accept an access token for the external API
- Accept a userId for tracking
- Return a configured MCP `Server` instance
- Register all tools internally
- **Tool Naming**: Tools must be named `{resourceType}_{tool_name}` (e.g., `instagram_get_profile`)

## Step-by-Step Bootstrap

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
│   ├── auth/
│   │   ├── platform-jwt-provider.ts    # Platform JWT validation
│   │   └── platform-token-resolver.ts  # Platform API integration
├── agent/
│   ├── integration-plan.md
│   ├── progress.yaml
│   ├── TOOL-NAMING-CONVENTION.md
│   └── tasks/
├── package.json
├── tsconfig.json
├── Dockerfile
├── cloudbuild.yaml
├── .env.example
├── .gitignore
└── README.md
```

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
    "start": "node dist/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4",
    "@prmichaelsen/mcp-auth": "^4.0.0",
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
  public jwtTokenCache = new Map<string, string>();
  
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
      
      // Store JWT for forwarding to credentials API
      this.jwtTokenCache.set(decoded.userId, token);
      
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
  
  getJWTToken(userId: string): string | undefined {
    return this.jwtTokenCache.get(userId);
  }
  
  async cleanup(): Promise<void> {
    this.authCache.clear();
    this.jwtTokenCache.clear();
  }
}
```

### Step 7: Create Platform Token Resolver

**src/auth/platform-token-resolver.ts**:

```typescript
import type {
  ResourceTokenResolver,
  CredentialsAPIResponse,
  CredentialsAPIHeaders,
  TenantAPIErrorResponse
} from '@prmichaelsen/mcp-auth';

export interface PlatformTokenResolverConfig {
  platformUrl: string;
  authProvider: PlatformJWTProvider;  // Reference to auth provider for JWT access
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
      
      // Call platform API with JWT (not service token)
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

### Step 8: Create Main Server

**src/index.ts**:

```typescript
#!/usr/bin/env node

import { wrapServer } from '@prmichaelsen/mcp-auth';
import { createYourServer } from '@your-org/your-mcp-base/factory';
import { PlatformJWTProvider } from './auth/platform-jwt-provider.js';
import { PlatformTokenResolver } from './auth/platform-token-resolver.js';

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

// Validate
if (!config.platform.serviceToken) {
  console.error('Error: PLATFORM_SERVICE_TOKEN required');
  process.exit(1);
}

if (!config.platform.url) {
  console.error('Error: PLATFORM_URL required');
  process.exit(1);
}

// Create providers
const authProvider = new PlatformJWTProvider({
  serviceToken: config.platform.serviceToken,
  issuer: 'agentbase.me',
  audience: 'mcp-server',
  cacheResults: true,
  cacheTtl: 60000
});

const tokenResolver = new PlatformTokenResolver({
  platformUrl: config.platform.url,
  authProvider: authProvider,  // Pass auth provider reference
  cacheTokens: true,
  cacheTtl: 300000
});

// Wrap server
const wrappedServer = wrapServer({
  serverFactory: (accessToken: string, userId: string) => {
    return createYourServer(accessToken, userId);
  },
  authProvider,
  tokenResolver,
  resourceType: 'your-resource-type', // e.g., 'github', 'slack', etc.
  transport: {
    type: 'sse',
    port: config.server.port,
    host: '0.0.0.0',
    basePath: '/mcp'
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

// Start
async function main() {
  await wrappedServer.start();
  console.log(`Server running on port ${config.server.port}`);
  console.log(`Endpoint: http://0.0.0.0:${config.server.port}/mcp`);
}

process.on('SIGINT', async () => {
  await wrappedServer.stop();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await wrappedServer.stop();
  process.exit(0);
});

main();
```

### Step 9: Create Dockerfile

**Dockerfile**:

```dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install ALL dependencies
RUN npm ci

# Copy source
COPY src ./src

# Build
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --omit=dev

# Copy built files
COPY --from=builder /app/dist ./dist

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://localhost:8080/mcp/health').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

CMD ["node", "dist/index.js"]
```

### Step 10: Create Environment Template

**.env.example**:

```env
# Platform JWT (shared secret for JWT validation)
PLATFORM_SERVICE_TOKEN=your-shared-secret

# Platform API (for token resolution)
PLATFORM_URL=https://your-platform.com

# Server
PORT=8080
NODE_ENV=development
LOG_LEVEL=info
```

### Step 11: Create .dockerignore

**.dockerignore**:

```
dist/
build/
node_modules/
.env
.env.local
.git/
*.md
agent/
.vscode/
*.log
```

### Step 12: Create .gitignore

**.gitignore**:

```
node_modules/
dist/
build/
.env
.env.local
*.log
.DS_Store
```

### Step 13: Deploy to Cloud Run

```bash
# Build locally
npm run build
docker build -t gcr.io/YOUR_PROJECT/your-mcp-server:latest .

# Push to GCR
docker push gcr.io/YOUR_PROJECT/your-mcp-server:latest

# Generate service token
SERVICE_TOKEN=$(node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))")

# Create secret
echo -n "$SERVICE_TOKEN" | gcloud secrets create platform-service-token --data-file=-

# Deploy
gcloud run deploy your-mcp-server \
  --image gcr.io/YOUR_PROJECT/your-mcp-server:latest \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars="PLATFORM_URL=https://your-platform.com,NODE_ENV=production" \
  --update-secrets=PLATFORM_SERVICE_TOKEN=platform-service-token:latest \
  --min-instances=0 \
  --max-instances=10 \
  --memory=512Mi \
  --cpu=1
```

## Base MCP Server Requirements

For this pattern to work, your base MCP server must:

### 1. Export a Server Factory

```typescript
// your-mcp-base/src/server-factory.ts

import { Server } from '@modelcontextprotocol/sdk/server/index.js';

export function createYourServer(
  accessToken: string,
  userId: string,
  options?: ServerOptions
): Server {
  // Create API client with user's token
  const client = new YourAPIClient(accessToken);
  
  // Create MCP server
  const server = new Server({
    name: 'your-server',
    version: '1.0.0'
  }, {
    capabilities: { tools: {} }
  });
  
  // Register all tools with {resourceType}_ prefix
  server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
      tools: [
        { name: 'yourservice_get_data', description: '...', inputSchema: {...} },
        { name: 'yourservice_create_item', description: '...', inputSchema: {...} },
        // All tools prefixed with resourceType
      ]
    };
  });
  
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    
    // Handle tool calls - names match the registered names
    switch (name) {
      case 'yourservice_get_data':
        // Handle tool
        break;
      case 'yourservice_create_item':
        // Handle tool
        break;
    }
  });
  
  return server;
}
```

**Important**: Tool names MUST follow the convention `{resourceType}_{tool_name}` where `resourceType` matches the value you'll use in `wrapServer()` config. See [TOOL-NAMING-CONVENTION.md](../TOOL-NAMING-CONVENTION.md) for details.

### 2. Package Exports

**package.json**:

```json
{
  "name": "@your-org/your-mcp-base",
  "exports": {
    ".": "./build/index.js",
    "./factory": "./build/server-factory.js",
    "./client": "./build/your-client.js",
    "./tools": "./build/tools/index.js"
  }
}
```

### 3. Build Configuration

Must generate:
- All source files as .js
- TypeScript declarations (.d.ts)
- Preserve directory structure

## Platform API Requirements

The platform must implement:

```typescript
// GET /api/credentials/:provider
// Headers: { Authorization: Bearer <jwt-token>, X-User-ID: <user-id> }

import type { CredentialsAPIResponse } from '@prmichaelsen/mcp-auth';
import jwt from 'jsonwebtoken';

export async function GET(request: Request, { params }: { params: { provider: string } }) {
  // 1. Validate JWT token (same secret as MCP server)
  const jwtToken = request.headers.get('Authorization')?.replace('Bearer ', '');
  if (!jwtToken) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  try {
    jwt.verify(jwtToken, process.env.PLATFORM_SERVICE_TOKEN!, {
      issuer: 'agentbase.me',
      audience: 'mcp-server'
    });
  } catch (error) {
    return Response.json({ error: 'Invalid token' }, { status: 401 });
  }
  
  // 2. Get userId
  const userId = request.headers.get('X-User-ID');
  if (!userId) {
    return Response.json({ error: 'X-User-ID required' }, { status: 400 });
  }
  
  // 3. Query database
  const credentials = await db.query(
    'SELECT access_token FROM credentials WHERE user_id = $1 AND provider = $2',
    [userId, params.provider]
  );
  
  if (!credentials.rows[0]) {
    return Response.json({ error: 'Credentials not found' }, { status: 404 });
  }
  
  // 4. Return token
  const response: CredentialsAPIResponse = {
    access_token: credentials.rows[0].access_token,
    expires_at: credentials.rows[0].expires_at,
    // ... other fields
  };
  
  return Response.json(response);
}
```

## Testing

### 1. Local Testing

```bash
# Start server
npm start

# Test health
curl http://localhost:8080/mcp/health

# Test with Platform JWT
# Generate test JWT (use your PLATFORM_SERVICE_TOKEN)
node -e "const jwt = require('jsonwebtoken'); console.log(jwt.sign({ userId: 'test-user' }, 'your-service-token', { issuer: 'agentbase.me', audience: 'mcp-server', expiresIn: '1h' }))"

# Test MCP endpoint
curl -X POST http://localhost:8080/mcp/message \
  -H "Authorization: Bearer <jwt-from-above>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

### 2. Production Testing

```bash
# Get Platform JWT from your platform
# Then test MCP endpoint
curl -X POST https://your-server.run.app/mcp/message \
  -H "Authorization: Bearer <platform-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

## Architecture Summary

```
Client (Platform JWT)
  ↓
Platform JWT Provider (validates JWT → userId)
  ↓
Platform Token Resolver (userId → API token via platform with JWT forwarding)
  ↓
Your MCP Server (executes tools with {resourceType}_ prefix)
  ↓
Your External API
```

## Key Benefits

1. **Zero modification** to base MCP server
2. **Automatic multi-tenancy** via server wrapping
3. **Platform JWT authentication** built-in
4. **JWT forwarding** to credentials API (single token flow)
5. **Platform-managed credentials** (secure)
6. **Stateless MCP server** (no database)
7. **Type-safe** with shared API contracts
8. **Production-ready** with health checks
9. **Tool naming convention** enforced ({resourceType}_{tool_name})

## Examples

- **Instagram**: [@prmichaelsen/agentbase-mcp-server](https://github.com/prmichaelsen/agentbase-mcp-server)
- **Base Pattern**: This document

## Common Integrations

### GitHub MCP Server
```typescript
import { createGitHubServer } from '@your-org/github-mcp/factory';
import { PlatformJWTProvider } from './auth/platform-jwt-provider.js';
import { PlatformTokenResolver } from './auth/platform-token-resolver.js';

const authProvider = new PlatformJWTProvider({
  serviceToken: process.env.PLATFORM_SERVICE_TOKEN!,
  issuer: 'agentbase.me',
  audience: 'mcp-server'
});

const wrapped = wrapServer({
  serverFactory: (accessToken, userId) => createGitHubServer(accessToken, userId),
  authProvider,
  tokenResolver: new PlatformTokenResolver({ platformUrl: 'https://platform.com', authProvider }),
  resourceType: 'github',  // Tools must be named github_*
  transport: { type: 'sse', port: 8080 }
});
```

### Slack MCP Server
```typescript
import { createSlackServer } from '@your-org/slack-mcp/factory';
import { PlatformJWTProvider } from './auth/platform-jwt-provider.js';
import { PlatformTokenResolver } from './auth/platform-token-resolver.js';

const authProvider = new PlatformJWTProvider({
  serviceToken: process.env.PLATFORM_SERVICE_TOKEN!,
  issuer: 'agentbase.me',
  audience: 'mcp-server'
});

const wrapped = wrapServer({
  serverFactory: (accessToken, userId) => createSlackServer(accessToken, userId),
  authProvider,
  tokenResolver: new PlatformTokenResolver({ platformUrl: 'https://platform.com', authProvider }),
  resourceType: 'slack',  // Tools must be named slack_*
  transport: { type: 'sse', port: 8080 }
});
```

## Summary

This pattern enables you to:
- ✅ Take any MCP server with a factory function
- ✅ Add Platform JWT authentication
- ✅ Add JWT forwarding to credentials API
- ✅ Add platform-managed credentials
- ✅ Deploy as multi-tenant service
- ✅ Zero modification to base server
- ✅ Enforce tool naming convention ({resourceType}_{tool_name})

**Total time**: ~4-6 hours for a new integration (most time is base server factory refactor)

**Result**: Production-ready multi-tenant MCP server with Platform JWT auth!

**See also**: [TOOL-NAMING-CONVENTION.md](../TOOL-NAMING-CONVENTION.md) for tool naming requirements
