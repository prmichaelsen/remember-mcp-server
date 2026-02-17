# Task 21: Unify Memory Schemas - Use Single Schema for All Collections

**Project**: remember-mcp (base library)
**Estimated Time**: 3 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Refactor the codebase to use a single unified memory schema for all memory collections (user collections and Memory_public), eliminating the separate space-schema.ts file and ensuring consistency across all collections.

## Problem Statement

**Current State**:
- User memory collections use schema defined in `weaviate/schema.ts`
- Public/space collections use schema defined in `weaviate/space-schema.ts`
- Two separate schema definitions that must be kept in sync manually
- Duplication of property definitions
- Risk of schema drift between user and public collections

**Issues**:
- Maintenance burden: changes must be made in two places
- Inconsistency risk: schemas can diverge
- Complexity: two schema files to understand
- The space schema was created to add space-specific fields, but these can be part of the main schema

**Goal**: One schema definition used by all memory collections (user and public).

---

## Solution Design

### Approach: Extend Main Schema with Space Fields

1. **Add space-specific fields to main schema** (`weaviate/schema.ts`):
   - `spaces: text[]` - Array of spaces this memory is published to
   - `author_id: text` - Original author user_id
   - `ghost_id: text` - Optional ghost profile ID
   - `attribution: text` - Attribution type ("user" or "ghost")
   - `published_at: text` - When published to space
   - `discovery_count: number` - How many times discovered

2. **Remove space-schema.ts**:
   - Delete `src/weaviate/space-schema.ts`
   - Delete `src/weaviate/space-schema.spec.ts`

3. **Update collection creation**:
   - User collections: ignore space fields (they'll be null/empty)
   - Public collection: use same schema, populate space fields
   - All collections use `createMemoryCollection()` from `schema.ts`

4. **Update imports**:
   - Replace `import from './space-schema.js'` with `import from './schema.js'`
   - Update `ensurePublicCollection()` to use main schema

### Benefits

- ✅ Single source of truth for schema
- ✅ Guaranteed consistency between user and public collections
- ✅ Easier maintenance (one file to update)
- ✅ Simpler codebase (fewer files)
- ✅ Space fields are optional, so user collections work fine
- ✅ Spread operator works perfectly (same schema)

---

## Implementation Steps

### 1. Add Space Fields to Main Schema

**File**: `src/weaviate/schema.ts`

**Actions**:
- Add space-specific properties to the main memory schema
- Add them after existing properties, before timestamps
- Mark them as optional in comments
- Ensure vectorizer configuration is identical

**Properties to Add**:
```typescript
// Space/publishing fields (optional, only used in Memory_public)
{
  name: 'spaces',
  dataType: 'text[]' as any,
  description: 'Spaces this memory is published to (e.g., ["the_void", "dogs"])',
},
{
  name: 'author_id',
  dataType: 'text' as any,
  description: 'Original author user_id (for permissions in shared spaces)',
},
{
  name: 'ghost_id',
  dataType: 'text' as any,
  description: 'Optional ghost profile ID for pseudonymous publishing',
},
{
  name: 'attribution',
  dataType: 'text' as any,
  description: 'Attribution type: "user" or "ghost"',
},
{
  name: 'published_at',
  dataType: 'text' as any,
  description: 'When published to space (ISO 8601)',
},
{
  name: 'discovery_count',
  dataType: 'number' as any,
  description: 'How many times discovered in shared spaces',
},
```

### 2. Update ensurePublicCollection()

**File**: `src/weaviate/space-schema.ts` → Move to `src/weaviate/schema.ts`

**Actions**:
- Move `ensurePublicCollection()` function to `schema.ts`
- Update it to use `createMemoryCollection()` from same file
- Remove `createSpaceCollection()` function
- Keep `PUBLIC_COLLECTION_NAME` constant
- Keep space validation functions (`isValidSpaceId`, etc.)

**New Implementation**:
```typescript
export async function ensurePublicCollection(
  client: WeaviateClient
): Promise<any> {
  const exists = await client.collections.exists(PUBLIC_COLLECTION_NAME);
  
  if (exists) {
    return client.collections.get(PUBLIC_COLLECTION_NAME);
  }
  
  // Use the same schema creation as user collections
  await createMemoryCollection(client, PUBLIC_COLLECTION_NAME);
  return client.collections.get(PUBLIC_COLLECTION_NAME);
}
```

### 3. Delete space-schema.ts Files

**Actions**:
- Delete `src/weaviate/space-schema.ts`
- Delete `src/weaviate/space-schema.spec.ts`
- Update any imports that referenced these files

### 4. Update All Imports

**Files to Update**:
- `src/tools/publish.ts`
- `src/tools/confirm.ts`
- `src/tools/query-space.ts`
- `src/tools/search-space.ts`

**Change**:
```typescript
// Before
import { ensurePublicCollection } from '../weaviate/space-schema.js';

// After
import { ensurePublicCollection } from '../weaviate/schema.js';
```

### 5. Update Schema Export

**File**: `src/weaviate/schema.ts`

**Actions**:
- Export `ensurePublicCollection`
- Export `PUBLIC_COLLECTION_NAME`
- Export space validation functions if needed

### 6. Update Tests

**Actions**:
- Update test imports
- Verify schema tests cover space fields
- Add tests for `ensurePublicCollection()` in schema.spec.ts
- Remove space-schema.spec.ts tests or merge into schema.spec.ts

---

## Verification

- [ ] Main schema includes all space-specific fields
- [ ] `ensurePublicCollection()` moved to schema.ts
- [ ] space-schema.ts deleted
- [ ] space-schema.spec.ts deleted
- [ ] All imports updated
- [ ] TypeScript compiles without errors
- [ ] All tests pass
- [ ] User collections still work (space fields are null/empty)
- [ ] Memory_public collection created with same schema
- [ ] Publish to The Void works
- [ ] Search The Void works (vectorizer present)
- [ ] Spread operator works (same schema)

---

## Testing Plan

### 1. Unit Tests

```typescript
describe('Unified Memory Schema', () => {
  it('should create user collection with space fields', async () => {
    await createMemoryCollection(client, 'Memory_testuser');
    // Verify schema includes space fields
  });
  
  it('should create public collection with same schema', async () => {
    await ensurePublicCollection(client);
    // Verify Memory_public has identical schema
  });
  
  it('should handle null space fields in user collections', async () => {
    // Insert memory without space fields
    // Verify it works
  });
  
  it('should handle populated space fields in public collection', async () => {
    // Insert memory with space fields
    // Verify all fields present
  });
});
```

### 2. Integration Tests

```typescript
describe('Publishing with Unified Schema', () => {
  it('should publish memory from user to public collection', async () => {
    // Create memory in user collection
    // Publish to The Void
    // Verify in Memory_public with space fields populated
  });
  
  it('should search public collection with vectorizer', async () => {
    // Publish memory
    // Search The Void
    // Verify semantic search works
  });
});
```

### 3. Manual Testing

1. **User Collection**:
   - Create memory in user collection
   - Verify space fields are null/empty
   - Search user memories (should work)

2. **Public Collection**:
   - Publish memory to The Void
   - Verify space fields populated
   - Search The Void (should work with vectorizer)

3. **Schema Consistency**:
   - Compare user and public collection schemas
   - Verify they're identical
   - Verify spread operator works

---

## Migration Strategy

### For Existing Deployments

**Option 1: Clean Slate** (Recommended for new/test environments):
1. Delete all Memory_* collections
2. Deploy new code
3. Collections will be recreated with unified schema

**Option 2: Gradual Migration** (For production with data):
1. Deploy new code (keeps existing collections)
2. New user collections use unified schema
3. Delete Memory_public (will be recreated on next publish)
4. Existing user collections continue working (schema is superset)

**Option 3: Full Migration** (For production with important data):
1. Export all data from all collections
2. Delete all collections
3. Deploy new code
4. Re-import data (will use unified schema)

---

## Rollback Plan

If issues arise:
1. Revert code changes
2. Restore space-schema.ts from git
3. Redeploy previous version
4. Existing collections continue working

---

## Impact Assessment

### Files Modified
- `src/weaviate/schema.ts` - Add space fields, add `ensurePublicCollection()`
- `src/tools/publish.ts` - Update import
- `src/tools/confirm.ts` - Update import
- `src/tools/query-space.ts` - Update import
- `src/tools/search-space.ts` - Update import

### Files Deleted
- `src/weaviate/space-schema.ts`
- `src/weaviate/space-schema.spec.ts`

### Breaking Changes
- None for API consumers
- Schema change requires collection recreation (handled automatically)

### Performance Impact
- None (same schema, just unified)
- Slightly larger schema for user collections (extra unused fields)
- Negligible storage impact (null fields don't take space)

---

## Benefits

1. **Maintainability**: One schema to update
2. **Consistency**: Guaranteed identical schemas
3. **Simplicity**: Fewer files, clearer architecture
4. **Reliability**: No risk of schema drift
5. **Developer Experience**: Easier to understand and modify

---

## Related Issues

- Task 20: `remember_update_memory` investigation (completed)
- Memory_public vectorizer issue (will be fixed by this refactoring)
- Schema evolution challenges (simplified by unification)

---

**Next Steps**:
1. Review and approve this design
2. Implement changes in remember-mcp
3. Test thoroughly
4. Deploy and verify
5. Update documentation

---

**Status**: Awaiting approval to proceed
**Priority**: Medium (improves architecture, fixes vectorizer issue)
**Risk**: Low (backwards compatible, easy rollback)
