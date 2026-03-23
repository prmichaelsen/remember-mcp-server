#!/usr/bin/env node

/**
 * Remember MCP Server - Multi-tenant wrapper with Platform JWT auth
 * 
 * This server wraps remember-mcp with authentication and multi-tenancy support.
 */

import { wrapServer, SimpleTokenResolver } from '@prmichaelsen/mcp-auth';
import { createServer as createRememberServer } from '@prmichaelsen/remember-mcp/factory';
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
  issuer: ['agentbase.me', 'memorycloud.chat'],
  audience: 'mcp-server',
  cacheResults: true,
  cacheTtl: 60000 // 60 seconds
});

// Wrap server with authentication
const wrappedServer = wrapServer({
  serverFactory: async (accessToken, userId, extras) => {
    // extras contains flat headers from mcp-auth (X-Internal-Type → internal_type, etc.)
    // createRememberServer normalizes these into structured ServerOptions internally
    console.log('[DEBUG] serverFactory called', {
      userId,
      internalType: extras?.internal_type,
      ghostOwner: extras?.ghost_owner,
      ghostType: extras?.ghost_type,
    });

    return await createRememberServer(accessToken, userId, extras);
  },
  authProvider,
  resourceType: 'remember',
  sessionMode: 'stateful',
  session: {
    idleTimeout: 300000,   // 5 min
    maxLifetime: 3600000,  // 1 hour
  },
  transport: {
    type: 'sse',
    port: config.server.port,
    host: '0.0.0.0',
    basePath: '/mcp',
    cors: true,
    corsOrigin: process.env.CORS_ORIGIN?.includes(',')
      ? process.env.CORS_ORIGIN.split(',').map(o => o.trim())
      : process.env.CORS_ORIGIN || 'https://agentbase.me',
    corsAllowedHeaders: [
      'X-Internal-Type',
      'X-Ghost-Owner',
      'X-Ghost-Type',
      'X-Ghost-Space',
      'X-Ghost-Group',
    ]
  },
  middleware: {
    rateLimit: {
      enabled: true,
      maxRequests: 1000,
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
    console.log(`✅ Remember MCP Server started successfully`);
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
