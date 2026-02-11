# Task 8: Implement Main Server

**Milestone**: Milestone 2 - Authentication Implementation
**Estimated Time**: 1 hour
**Dependencies**: Task 7
**Status**: Not Started

---

## Objective

Implement the main server entry point that integrates the authentication providers and wraps the base server (placeholder for now, actual integration in Milestone 3).

## Steps

1. **Import dependencies**
   - Import wrapServer from mcp-auth
   - Import PlatformJWTProvider
   - Import PlatformTokenResolver
   - Import Server from MCP SDK (for placeholder)

2. **Load configuration from environment**
   - PLATFORM_SERVICE_TOKEN (required)
   - PLATFORM_URL (required)
   - PORT (default: 8080)
   - NODE_ENV
   - LOG_LEVEL

3. **Validate required configuration**
   - Check PLATFORM_SERVICE_TOKEN exists
   - Check PLATFORM_URL exists
   - Exit with error if missing

4. **Create auth provider instance**
   - Initialize PlatformJWTProvider
   - Configure issuer: 'agentbase.me'
   - Configure audience: 'mcp-server'
   - Enable caching with 60s TTL

5. **Create token resolver instance**
   - Initialize PlatformTokenResolver
   - Pass auth provider reference
   - Enable caching with 5min TTL

6. **Create placeholder server factory**
   - For now, create a simple MCP server
   - Will be replaced with remember-mcp in Milestone 3
   - Add TODO comment

7. **Wrap server with authentication**
   - Call wrapServer() with config
   - Set resourceType to 'remember'
   - Configure SSE transport
   - Enable rate limiting
   - Enable logging

8. **Start server**
   - Call wrappedServer.start()
   - Log server URL
   - Handle SIGINT/SIGTERM for graceful shutdown

## Verification

- [ ] File compiles without TypeScript errors
- [ ] Server starts without errors
- [ ] Configuration validation works
- [ ] Auth provider is initialized
- [ ] Token resolver is initialized
- [ ] Server listens on configured port
- [ ] Graceful shutdown works

## Implementation Reference

See [`agent/patterns/bootstrap.md`](../patterns/bootstrap.md) Step 8 for complete implementation example.

---

**Next Task**: [Task 9: Add Health Check Endpoint](task-9-health-check.md)
