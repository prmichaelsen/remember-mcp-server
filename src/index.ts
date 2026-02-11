#!/usr/bin/env node

/**
 * Remember MCP Server - Multi-tenant wrapper with Platform JWT auth
 * 
 * This server wraps remember-mcp with authentication and multi-tenancy support.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { wrapServer } from '@prmichaelsen/mcp-auth';
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

// Create token resolver
const tokenResolver = new PlatformTokenResolver({
  platformUrl: config.platform.url,
  authProvider: authProvider,
  cacheTokens: true,
  cacheTtl: 300000 // 5 minutes
});

// TODO: Replace with actual remember-mcp server factory in Milestone 3
// For now, create a placeholder server factory
function createPlaceholderServer(accessToken: string, userId: string): Server {
  const server = new Server({
    name: 'remember-mcp-server',
    version: '1.0.0'
  }, {
    capabilities: {
      tools: {}
    }
  });
  
  // TODO: Import and use createRememberServer from @prmichaelsen/remember-mcp
  // TODO: Ensure tools are prefixed with 'remember_'
  
  console.log(`Created placeholder server for user: ${userId}`);
  
  return server;
}

// Wrap server with authentication
const wrappedServer = wrapServer({
  serverFactory: (accessToken: string, userId: string) => {
    return createPlaceholderServer(accessToken, userId);
  },
  authProvider,
  tokenResolver,
  resourceType: 'remember',
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
