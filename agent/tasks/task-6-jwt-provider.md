# Task 6: Implement Platform JWT Provider

**Milestone**: Milestone 2 - Authentication Implementation
**Estimated Time**: 1.5 hours
**Dependencies**: Task 5
**Status**: Not Started

---

## Objective

Implement the PlatformJWTProvider class that validates Platform JWTs, extracts user information, and caches authentication results.

## Steps

1. **Import required dependencies**
   - Import AuthProvider, AuthResult, RequestContext from mcp-auth
   - Import jsonwebtoken for JWT validation

2. **Define configuration interface**
   - serviceToken: JWT signing secret
   - issuer: JWT issuer (agentbase.me)
   - audience: JWT audience (mcp-server)
   - cacheResults: Enable/disable caching
   - cacheTtl: Cache time-to-live

3. **Implement PlatformJWTProvider class**
   - Implement AuthProvider interface
   - Add authentication cache (Map)
   - Add JWT token cache for forwarding

4. **Implement initialize() method**
   - Log initialization message
   - Return Promise<void>

5. **Implement authenticate() method**
   - Extract Authorization header
   - Validate Bearer token format
   - Check cache for existing result
   - Verify JWT with jsonwebtoken
   - Extract userId and email from claims
   - Store JWT in token cache
   - Cache authentication result
   - Return AuthResult

6. **Implement getJWTToken() method**
   - Return cached JWT for userId
   - Used by token resolver

7. **Implement cleanup() method**
   - Clear authentication cache
   - Clear JWT token cache

## Verification

- [ ] File compiles without TypeScript errors
- [ ] All methods implement AuthProvider interface
- [ ] JWT validation works with test token
- [ ] Invalid JWTs are rejected
- [ ] Caching works correctly
- [ ] getJWTToken() returns stored JWT
- [ ] cleanup() clears all caches

## Implementation Reference

See [`agent/patterns/bootstrap.md`](../patterns/bootstrap.md) Step 6 for complete implementation example.

---

**Next Task**: [Task 7: Implement Platform Token Resolver](task-7-token-resolver.md)
