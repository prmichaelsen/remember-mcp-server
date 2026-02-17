# Task 20: Investigate `remember_update_memory` "Not Found" Error

**Project**: remember-mcp (base library)
**Estimated Time**: 2 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Investigate why `remember_update_memory` reports "Memory not found" for memories that verifiably exist in Weaviate with all required properties (including `parent_id: ""`).

## Problem Statement

**Symptoms**:
- `remember_update_memory` fails with "Memory not found: {id}"
- The memory DOES exist in the user's Weaviate collection
- The memory HAS `parent_id` set to `""` (empty string)
- Other tools (`remember_search`, `remember_confirm`) successfully find and operate on memories

**Affected Memories**:
- Memory ID: `01939c16-61a1-7c5d-a9d7-1a1e3e6ed5f2`
- Memory ID: `01939283-6755-7cac-8bff-07e58aff4bf7`
- User: `MnOyIarhz5b8n06TsTovM582NSG2`
- Collection: `Memory_MnOyIarhz5b8n06TsTovM582NSG2`

**Error Details**:
```
Error: Memory not found: 01939c16-61a1-7c5d-a9d7-1a1e3e6ed5f2. 
It may have been deleted or never existed.
at handleUpdateMemory (remember-mcp/dist/server-factory.js:1956)
```

**Timestamp**: 2026-02-17T02:55:02

## Investigation Steps

### 1. Review `handleUpdateMemory()` Source Code

**Actions**:
- Read `src/tools/update-memory.ts` in remember-mcp
- Examine the query method used to fetch the memory
- Check if it uses `fetchMemoryWithAllProperties()` or a different method
- Look for error handling that converts query errors to "not found"

**Questions to Answer**:
- What query method does it use?
- Does it fetch all properties or specific properties?
- How does it handle query errors?
- Is there a try-catch that masks the real error?

### 2. Compare with Working Tools

**Actions**:
- Compare `handleUpdateMemory()` with `handlePublish()` (which works)
- Compare with `handleSearch()` (which works)
- Identify differences in query approach
- Document why some queries succeed and others fail

**Key Differences to Look For**:
- Property selection in queries
- Error handling patterns
- Collection access methods
- Filter conditions

### 3. Test Query Methods Directly

**Actions**:
- Create a test script that queries the specific memory
- Try different query methods:
  - `fetchObjectById()` with no properties
  - `fetchObjectById()` with specific properties
  - `fetchObjectById()` with all properties
- Document which methods succeed and which fail

**Test Script**:
```typescript
const collection = client.collections.get('Memory_MnOyIarhz5b8n06TsTovM582NSG2');

// Test 1: Fetch by ID with no property specification
const result1 = await collection.query.fetchObjectById('01939c16-61a1-7c5d-a9d7-1a1e3e6ed5f2');

// Test 2: Fetch with specific properties
const result2 = await collection.query.fetchObjectById('01939c16-61a1-7c5d-a9d7-1a1e3e6ed5f2', {
  returnProperties: ['content', 'user_id', 'created_at']
});

// Test 3: Fetch with parent_id included
const result3 = await collection.query.fetchObjectById('01939c16-61a1-7c5d-a9d7-1a1e3e6ed5f2', {
  returnProperties: ['content', 'user_id', 'parent_id']
});
```

### 4. Check Error Handling in `handleUpdateMemory()`

**Actions**:
- Look for try-catch blocks in `handleUpdateMemory()`
- Check if query errors are being caught and converted to "not found"
- Verify error messages match the actual error type
- Determine if the real error is being masked

**Code Pattern to Look For**:
```typescript
try {
  const memory = await fetchMemory(id);
  if (!memory) {
    throw new Error('Memory not found');
  }
} catch (error) {
  // Is this catching query errors and reporting as "not found"?
  throw new Error(`Memory not found: ${id}`);
}
```

### 5. Review Property Fetching Logic

**Actions**:
- Check if `fetchMemoryWithAllProperties()` is used
- Verify which properties it tries to fetch
- Test if removing `parent_id` from the query fixes the issue
- Document the property fetching behavior

### 6. Reproduce the Issue Locally

**Actions**:
- Set up local remember-mcp instance
- Create a test memory with `parent_id: ""`
- Try to update it with `remember_update_memory`
- Capture the actual error (not the masked one)
- Compare with production behavior

### 7. Propose Solution

**Based on findings, propose one of**:
- Fix query method to handle empty string properties
- Fix error handling to report actual errors
- Update property fetching to be more selective
- Add better error messages for debugging

## Verification

- [ ] Source code for `handleUpdateMemory()` reviewed
- [ ] Query method identified and documented
- [ ] Error handling pattern documented
- [ ] Comparison with working tools completed
- [ ] Test queries executed successfully
- [ ] Root cause identified
- [ ] Solution proposed and documented
- [ ] Test case created to prevent regression

## Expected Findings

**Hypothesis**: `handleUpdateMemory()` uses `fetchMemoryWithAllProperties()` which fails when querying properties, but the error is caught and converted to "Memory not found" instead of reporting the actual query error.

**Expected Solution**: Either:
1. Use a more selective property fetch (only fetch properties being updated)
2. Fix error handling to report actual query errors
3. Update `fetchMemoryWithAllProperties()` to handle empty string properties gracefully

## Related Issues

- Issue #1: `remember_publish` failing with "no such prop 'parent_id'" (same root cause)
- Migration script updated to use `""` instead of `null`
- Some memories work, some don't (inconsistent data state)

## Files to Review

- `remember-mcp/src/tools/update-memory.ts`
- `remember-mcp/src/tools/publish.ts` (for comparison)
- `remember-mcp/src/weaviate/client.ts` (query methods)
- `remember-mcp/src/utils/fetch-memory.ts` (if exists)

---

**Next Task**: TBD based on investigation findings
**Blockers**: None - investigation can proceed immediately
