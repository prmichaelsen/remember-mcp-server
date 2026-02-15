# Task 19: Debug remember_search_memory Hanging Issue

**Milestone**: Milestone 4 - Deployment and Production Testing
**Estimated Time**: 2-3 hours
**Dependencies**: Task 16 (Production Testing)
**Status**: Not Started

---

## Objective

Add detailed logging and error handling to debug why `remember_search_memory` tool calls appear to be hanging in production. The server logs show "Request handled successfully" but clients report "Failed to update memory" errors and hanging tool calls.

## Problem Statement

Current symptoms:
1. Client reports "Failed to update memory" errors
2. `remember_search_memory` tool calls appear to hang
3. Server logs only show generic "Request handled successfully" messages
4. No error logs or exceptions visible in Cloud Run logs
5. All HTTP requests return 200 status codes

The issue appears to be that:
- Server is completing requests successfully (from its perspective)
- But clients are not receiving responses or timing out
- No detailed logging exists to track tool execution flow

## Steps

### 1. Add Detailed Tool Execution Logging

Add logging to track tool execution in the remember-mcp server:

```typescript
// In the tool handler for remember_search_memory
console.log('[TOOL] remember_search_memory called', {
  query: args.query,
  userId: context.userId,
  timestamp: new Date().toISOString()
});

const startTime = Date.now();

try {
  // ... existing search logic ...
  
  const duration = Date.now() - startTime;
  console.log('[TOOL] remember_search_memory completed', {
    query: args.query,
    resultCount: results.length,
    duration: `${duration}ms`,
    userId: context.userId
  });
  
  return results;
} catch (error) {
  const duration = Date.now() - startTime;
  console.error('[TOOL] remember_search_memory failed', {
    query: args.query,
    error: error.message,
    stack: error.stack,
    duration: `${duration}ms`,
    userId: context.userId
  });
  throw error;
}
```

### 2. Add Database Query Logging

Add logging for Weaviate queries:

```typescript
// In database query functions
console.log('[WEAVIATE] Starting search query', {
  query: searchQuery,
  userId,
  timestamp: new Date().toISOString()
});

const queryStartTime = Date.now();

try {
  const results = await weaviateClient.query(...);
  
  const queryDuration = Date.now() - queryStartTime;
  console.log('[WEAVIATE] Query completed', {
    resultCount: results.length,
    duration: `${queryDuration}ms`,
    userId
  });
  
  return results;
} catch (error) {
  const queryDuration = Date.now() - queryStartTime;
  console.error('[WEAVIATE] Query failed', {
    error: error.message,
    duration: `${queryDuration}ms`,
    userId
  });
  throw error;
}
```

### 3. Add Request/Response Logging

Add logging at the MCP message handler level:

```typescript
// In the MCP message handler
console.log('[MCP] Incoming tool call', {
  tool: message.params.name,
  args: message.params.arguments,
  userId: context.userId,
  timestamp: new Date().toISOString()
});

const requestStartTime = Date.now();

try {
  const result = await handleToolCall(message);
  
  const requestDuration = Date.now() - requestStartTime;
  console.log('[MCP] Tool call completed', {
    tool: message.params.name,
    success: true,
    duration: `${requestDuration}ms`,
    userId: context.userId
  });
  
  return result;
} catch (error) {
  const requestDuration = Date.now() - requestStartTime;
  console.error('[MCP] Tool call failed', {
    tool: message.params.name,
    error: error.message,
    stack: error.stack,
    duration: `${requestDuration}ms`,
    userId: context.userId
  });
  throw error;
}
```

### 4. Add Timeout Detection

Add timeout warnings for slow operations:

```typescript
// Add timeout warning for operations taking >5 seconds
const SLOW_OPERATION_THRESHOLD = 5000; // 5 seconds

const timeoutWarning = setTimeout(() => {
  console.warn('[PERFORMANCE] Operation taking longer than expected', {
    tool: 'remember_search_memory',
    query: args.query,
    duration: `>${SLOW_OPERATION_THRESHOLD}ms`,
    userId: context.userId
  });
}, SLOW_OPERATION_THRESHOLD);

try {
  const result = await performSearch(args);
  clearTimeout(timeoutWarning);
  return result;
} catch (error) {
  clearTimeout(timeoutWarning);
  throw error;
}
```

### 5. Add Error Boundary Logging

Wrap all tool handlers with comprehensive error logging:

```typescript
// Error boundary wrapper
async function withErrorLogging(toolName: string, handler: Function, args: any, context: any) {
  const startTime = Date.now();
  
  try {
    console.log(`[TOOL_START] ${toolName}`, {
      args,
      userId: context.userId,
      timestamp: new Date().toISOString()
    });
    
    const result = await handler(args, context);
    
    const duration = Date.now() - startTime;
    console.log(`[TOOL_SUCCESS] ${toolName}`, {
      duration: `${duration}ms`,
      userId: context.userId
    });
    
    return result;
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`[TOOL_ERROR] ${toolName}`, {
      error: {
        message: error.message,
        name: error.name,
        stack: error.stack,
        code: error.code
      },
      duration: `${duration}ms`,
      userId: context.userId,
      args
    });
    
    throw error;
  }
}
```

### 6. Deploy and Test

1. Build and deploy the updated code:
   ```bash
   gcloud builds submit --config=cloudbuild.yaml --substitutions=COMMIT_SHA=$(git rev-parse --short HEAD)
   ```

2. Test the `remember_search_memory` tool from the client

3. Pull logs and analyze:
   ```bash
   gcloud run services logs read remember-mcp-server --region=us-central1 --limit=100 --freshness=5m
   ```

4. Look for:
   - `[TOOL_START]` and `[TOOL_SUCCESS]` pairs
   - Any `[TOOL_ERROR]` entries
   - Duration times for operations
   - Any `[PERFORMANCE]` warnings
   - Weaviate query timing

### 7. Analyze Results

Based on the logs, determine:
- Is the tool being called?
- Is it completing successfully?
- How long does it take?
- Are there any errors being caught?
- Is Weaviate responding?
- Is the response being sent back to the client?

## Verification

- [ ] Detailed logging added for all tool calls
- [ ] Database query logging implemented
- [ ] Request/response logging added
- [ ] Timeout detection implemented
- [ ] Error boundary logging added
- [ ] Code deployed to Cloud Run
- [ ] Logs show detailed execution flow
- [ ] Can identify where requests are hanging or failing
- [ ] Error messages are descriptive and actionable

## Expected Outcomes

After this task, we should be able to:
1. See exactly when `remember_search_memory` is called
2. Track how long each operation takes
3. Identify if errors are occurring but not being logged
4. Determine if the issue is in the search, database query, or response sending
5. Have actionable information to fix the root cause

## Files to Modify

- `src/index.ts` - Main server file (likely contains tool handlers)
- Any database query files (Weaviate client code)
- MCP message handler code
- Tool handler implementations

## Notes

- Use structured logging with consistent prefixes (`[TOOL]`, `[WEAVIATE]`, `[MCP]`) for easy filtering
- Include timing information for all operations
- Log both success and failure cases
- Include user context in all logs for debugging
- Don't log sensitive data (tokens, passwords, etc.)
- Consider adding a `DEBUG` environment variable to control log verbosity

---

**Next Task**: Task 20 - Fix root cause based on debugging findings
**Blockers**: None
