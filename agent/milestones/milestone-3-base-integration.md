# Milestone 3: Base Server Integration

**Goal**: Integrate remember-mcp base server with authentication wrapper
**Duration**: 4-6 hours
**Dependencies**: Milestone 2, remember-mcp factory export
**Status**: Not Started

---

## Overview

Integrate the remember-mcp base server by ensuring it exports a proper factory function, verifying tool naming conventions, and connecting it with the authentication wrapper.

## Deliverables

1. **Base Server Factory**
   - Verify remember-mcp exports factory function
   - Ensure signature matches: `createRememberServer(accessToken: string, userId: string): Server`
   - Confirm tools are prefixed with `remember_`

2. **Server Integration**
   - Import factory from remember-mcp
   - Pass factory to wrapServer()
   - Configure resourceType as 'remember'
   - Test tool listing

3. **User Isolation**
   - Verify per-user memory storage
   - Test cross-user isolation
   - Confirm userId is passed correctly

## Success Criteria

- [ ] remember-mcp factory is importable
- [ ] Factory signature is correct
- [ ] All tools are prefixed with `remember_`
- [ ] Server wrapping works without errors
- [ ] Tool listing returns correct tools
- [ ] Per-user storage isolation works
- [ ] Multiple users can use server simultaneously

## Key Files to Modify

1. `src/index.ts` - Add remember-mcp import and integration
2. `package.json` - Add remember-mcp dependency

## Tasks

This milestone consists of the following tasks:
1. [Task 10: Verify Base Server Factory](../tasks/task-10-verify-factory.md)
2. [Task 11: Integrate Base Server](../tasks/task-11-integrate-base.md)
3. [Task 12: Test User Isolation](../tasks/task-12-test-isolation.md)

---

**Next Milestone**: [Milestone 4: Deployment](milestone-4-deployment.md)
**Blockers**: remember-mcp must export factory function
