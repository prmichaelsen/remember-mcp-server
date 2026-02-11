# Task 7: Implement Platform Token Resolver

**Milestone**: Milestone 2 - Authentication Implementation
**Estimated Time**: 1.5 hours
**Dependencies**: Task 6
**Status**: Not Started

---

## Objective

Implement the PlatformTokenResolver class that fetches user credentials from the platform API using JWT forwarding.

## Steps

1. **Import required dependencies**
   - Import ResourceTokenResolver types from mcp-auth
   - Import PlatformJWTProvider for JWT access

2. **Define configuration interface**
   - platformUrl: Platform API base URL
   - authProvider: Reference to PlatformJWTProvider
   - cacheTokens: Enable/disable caching
   - cacheTtl: Cache time-to-live

3. **Implement PlatformTokenResolver class**
   - Implement ResourceTokenResolver interface
   - Add token cache (Map)

4. **Implement initialize() method**
   - Log initialization message
   - Return Promise<void>

5. **Implement resolveToken() method**
   - Check token cache
   - Get JWT from auth provider
   - Call platform API with JWT in Authorization header
   - Add X-User-ID header
   - Handle 404 (no credentials) gracefully
   - Parse response and extract access_token
   - Cache token
   - Return token or null

6. **Implement cleanup() method**
   - Clear token cache

## Verification

- [ ] File compiles without TypeScript errors
- [ ] All methods implement ResourceTokenResolver interface
- [ ] Can fetch JWT from auth provider
- [ ] Makes correct API call to platform
- [ ] Handles 404 responses gracefully
- [ ] Caching works correctly
- [ ] cleanup() clears cache

## Implementation Reference

See [`agent/patterns/bootstrap.md`](../patterns/bootstrap.md) Step 7 for complete implementation example.

---

**Next Task**: [Task 8: Implement Main Server](task-8-main-server.md)
