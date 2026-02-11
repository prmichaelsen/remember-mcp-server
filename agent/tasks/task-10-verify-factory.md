# Task 10: Verify Base Server Factory

**Milestone**: Milestone 3 - Base Server Integration
**Estimated Time**: 2 hours
**Dependencies**: Task 9, remember-mcp base server
**Status**: Not Started

---

## Objective

Verify that the remember-mcp base server exports a proper factory function and follows the required conventions for multi-tenant operation.

## Steps

1. **Check remember-mcp project location**
   - Verify project exists at `/home/prmichaelsen/remember-mcp`
   - Review project structure

2. **Verify factory function export**
   - Check if `createRememberServer()` function exists
   - Verify function signature: `(accessToken: string, userId: string) => Server`
   - Check if it's exported from main entry point

3. **Verify tool naming convention**
   - All tools must be prefixed with `remember_`
   - Examples: `remember_store`, `remember_recall`, `remember_list`
   - Check ListToolsRequestSchema handler

4. **Verify per-user storage**
   - Check if storage is isolated by userId
   - Verify no cross-user data access
   - Review storage implementation

5. **If modifications needed**
   - Document required changes
   - Create factory function if missing
   - Update tool names if needed
   - Implement per-user storage if needed

## Verification

- [ ] remember-mcp project exists and is accessible
- [ ] Factory function exists with correct signature
- [ ] All tools are prefixed with `remember_`
- [ ] Storage is isolated per userId
- [ ] No TypeScript compilation errors
- [ ] Factory can be imported from package

## Expected Factory Structure

```typescript
// remember-mcp/src/server-factory.ts

import { Server } from '@modelcontextprotocol/sdk/server/index.js';

export function createRememberServer(
  accessToken: string,
  userId: string
): Server {
  // Create storage instance for this user
  const storage = createUserStorage(userId);
  
  // Create MCP server
  const server = new Server({
    name: 'remember-mcp',
    version: '1.0.0'
  }, {
    capabilities: { tools: {} }
  });
  
  // Register tools with remember_ prefix
  server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
      tools: [
        { name: 'remember_store', description: '...', inputSchema: {...} },
        { name: 'remember_recall', description: '...', inputSchema: {...} },
        { name: 'remember_list', description: '...', inputSchema: {...} },
        // All tools prefixed with remember_
      ]
    };
  });
  
  // Handle tool calls
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    
    switch (name) {
      case 'remember_store':
        // Use user-specific storage
        break;
      case 'remember_recall':
        // Use user-specific storage
        break;
      // ...
    }
  });
  
  return server;
}
```

## If Base Server Needs Modifications

Document the changes needed and either:
1. Make changes to remember-mcp project
2. Create a wrapper/adapter in this project
3. Note as blocker for project completion

---

**Next Task**: [Task 11: Integrate Base Server](task-11-integrate-base.md)
**Blocker**: remember-mcp must export factory function
