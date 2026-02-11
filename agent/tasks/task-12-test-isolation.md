# Task 12: Test User Isolation

**Milestone**: Milestone 3 - Base Server Integration
**Estimated Time**: 1 hour
**Dependencies**: Task 11
**Status**: Not Started

---

## Objective

Verify that the integrated remember-mcp server properly isolates user data and that multiple users can use the service simultaneously without cross-user data access.

## Steps

1. **Review user isolation implementation**
   - Check how remember-mcp uses userId parameter
   - Verify Weaviate collections are per-user
   - Verify Firestore paths are per-user

2. **Create test script**
   - Generate test JWTs for multiple users
   - Test creating memories for different users
   - Test searching memories per user

3. **Test multi-user scenarios**
   - User A creates memory
   - User B creates memory
   - User A searches (should only see their memory)
   - User B searches (should only see their memory)

4. **Verify no cross-user access**
   - Confirm User A cannot see User B's memories
   - Confirm User B cannot see User A's memories
   - Check database collections/paths

5. **Document findings**
   - Document isolation mechanism
   - Note any issues found
   - Confirm security boundaries

## Verification

- [ ] remember-mcp uses userId for all operations
- [ ] Weaviate collections are scoped per user
- [ ] Firestore paths are scoped per user
- [ ] Multiple users can use service simultaneously
- [ ] No cross-user data leakage
- [ ] All tests pass

## Test Commands

```bash
# Generate test JWT for user1
node -e "const jwt = require('jsonwebtoken'); console.log(jwt.sign({ userId: 'test-user-1', email: 'user1@test.com' }, process.env.PLATFORM_SERVICE_TOKEN, { issuer: 'agentbase.me', audience: 'mcp-server', expiresIn: '1h' }))"

# Generate test JWT for user2
node -e "const jwt = require('jsonwebtoken'); console.log(jwt.sign({ userId: 'test-user-2', email: 'user2@test.com' }, process.env.PLATFORM_SERVICE_TOKEN, { issuer: 'agentbase.me', audience: 'mcp-server', expiresIn: '1h' }))"

# Test with user1 JWT
curl -X POST http://localhost:8080/mcp/message \
  -H "Authorization: Bearer <user1-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'

# Test with user2 JWT
curl -X POST http://localhost:8080/mcp/message \
  -H "Authorization: Bearer <user2-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

## Expected Behavior

From remember-mcp implementation:
- Weaviate collection: `Memory_{userId}` (e.g., `Memory_test-user-1`)
- Firestore path: `users/{userId}` (e.g., `users/test-user-1`)
- All operations scoped to userId parameter

---

**Next Task**: Task 13 (Milestone 4)
**Milestone Complete**: After this task, Milestone 3 is complete
