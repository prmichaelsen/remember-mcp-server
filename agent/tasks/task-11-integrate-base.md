# Task 11: Integrate Base Server

**Milestone**: Milestone 3 - Base Server Integration
**Estimated Time**: 1.5 hours
**Dependencies**: Task 10
**Status**: Not Started

---

## Objective

Integrate the remember-mcp base server by importing the factory function and replacing the placeholder server.

## Steps

1. **Add remember-mcp dependency**
   - Add `@prmichaelsen/remember-mcp` to package.json
   - Install dependency with npm install

2. **Update src/index.ts**
   - Import `createServer` from `@prmichaelsen/remember-mcp/factory`
   - Replace placeholder factory with actual factory
   - Remove TODO comments

3. **Verify imports**
   - Check that factory is importable
   - Verify TypeScript types are available

4. **Build and test**
   - Run `npm run build`
   - Verify compilation succeeds
   - Check dist/ output

5. **Test server startup**
   - Start server with `npm run dev`
   - Verify server starts without errors
   - Check tool listing

## Verification

- [ ] Dependency added to package.json
- [ ] npm install completes successfully
- [ ] Import statement works
- [ ] TypeScript compilation succeeds
- [ ] Server starts without errors
- [ ] Tools are listed with `remember_` prefix
- [ ] No placeholder code remains

## Implementation

Update [`src/index.ts`](../../../src/index.ts):

```typescript
// Replace this:
// TODO: Replace with actual remember-mcp server factory in Milestone 3
function createPlaceholderServer(accessToken: string, userId: string): Server {
  // ...
}

// With this:
import { createServer as createRememberServer } from '@prmichaelsen/remember-mcp/factory';

// And use it in wrapServer:
const wrappedServer = wrapServer({
  serverFactory: (accessToken: string, userId: string) => {
    return createRememberServer(accessToken, userId);
  },
  // ... rest of config
});
```

---

**Next Task**: [Task 12: Test User Isolation](task-12-test-isolation.md)
