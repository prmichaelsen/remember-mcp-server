# Task 16: Production Testing

**Milestone**: Milestone 4 - Deployment and Testing
**Estimated Time**: 1 hour
**Dependencies**: Task 15
**Status**: Not Started

---

## Objective

Perform comprehensive testing of the deployed production service with real platform integration.

## Steps

1. **Test health check**
   ```bash
   curl https://YOUR-SERVICE-URL/mcp/health
   ```

2. **Get Platform JWT from agentbase.me**
   - Log into agentbase.me
   - Generate JWT for testing
   - Verify JWT includes userId claim

3. **Test tool listing**
   ```bash
   curl -X POST https://YOUR-SERVICE-URL/mcp/message \
     -H "Authorization: Bearer <platform-jwt>" \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
   ```

4. **Test remember_create_memory**
   ```bash
   curl -X POST https://YOUR-SERVICE-URL/mcp/message \
     -H "Authorization: Bearer <platform-jwt>" \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc":"2.0",
       "method":"tools/call",
       "params":{
         "name":"remember_create_memory",
         "arguments":{"content":"Test memory from production"}
       },
       "id":2
     }'
   ```

5. **Test remember_search_memory**
   ```bash
   curl -X POST https://YOUR-SERVICE-URL/mcp/message \
     -H "Authorization: Bearer <platform-jwt>" \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc":"2.0",
       "method":"tools/call",
       "params":{
         "name":"remember_search_memory",
         "arguments":{"query":"test"}
       },
       "id":3
     }'
   ```

6. **Test multi-user isolation**
   - Get JWTs for two different users
   - Create memory with user1
   - Search with user2
   - Verify user2 cannot see user1's memory

7. **Test error handling**
   - Test with invalid JWT
   - Test with expired JWT
   - Test with missing credentials
   - Verify appropriate error responses

8. **Monitor logs**
   ```bash
   gcloud run logs read remember-mcp-server --region us-central1 --limit=50
   ```

## Verification

- [ ] Health check responds correctly
- [ ] Platform JWT authentication works
- [ ] All tools are accessible
- [ ] remember_create_memory works
- [ ] remember_search_memory works
- [ ] remember_delete_memory works
- [ ] User isolation is enforced
- [ ] Error handling works correctly
- [ ] No errors in production logs
- [ ] Performance is acceptable

---

**Next Task**: [Task 17: Complete Documentation](task-17-documentation.md)
