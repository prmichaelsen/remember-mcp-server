# Task 22: Identify Performance Enhancements

**Milestone**: [M5 - Performance Optimization](../milestones/milestone-5-performance.md)
**Estimated Time**: 2-3 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Audit the remember-mcp-server wrapper for performance bottlenecks and produce a prioritized list of enhancements that can be made **in this project** (not upstream).

---

## Context

The server is a thin wrapper around remember-mcp with authentication via mcp-auth. The current architecture per-request:

1. **JWT validation** — `PlatformJWTProvider.authenticate()` verifies token, extracts userId (cached 60s)
2. **Server factory** — `createRememberServer(accessToken, userId, opts)` creates a new remember-mcp instance per SSE connection
3. **SSE transport** — mcp-auth manages the HTTP/SSE lifecycle

The wrapper has three source files:
- `src/index.ts` — config, wrapServer() call, graceful shutdown
- `src/auth/platform-jwt-provider.ts` — JWT validation + auth cache
- `src/auth/platform-token-resolver.ts` — credentials API client (currently unused in static mode)

Cloud Run config: 0-10 instances, 512Mi memory, 1 CPU, 60s timeout.

### Known Performance Characteristics
- Cold start: ~2-5s (container boot + Node.js + dependency loading)
- JWT validation: <1ms when cached, ~1ms when not (symmetric HS256)
- Server factory: unknown latency — calls into remember-mcp which initializes Weaviate collections
- Build time: ~55-70s via Cloud Build

---

## Steps

### 1. Profile Request Lifecycle

Instrument the wrapper to measure each phase of a request:

**Measure**:
- Time from SSE connection to first byte
- JWT validation time (cache hit vs miss)
- `createRememberServer()` call duration
- Time from tool call to tool response (round-trip through remember-mcp)

**Method**:
- Add `console.time()`/`console.timeEnd()` around each phase in `src/index.ts`
- Deploy with timing instrumentation
- Trigger requests from agentbase.me and collect Cloud Run logs
- Compare cache-hit vs cache-miss scenarios

### 2. Audit Auth Layer

Review auth caching for optimization opportunities.

**Questions to answer**:
- Is the 60s auth cache TTL optimal? Could it be longer?
- Is the auth cache key (full JWT string) efficient? Could use a hash instead.
- Does `jwtTokenCache` (Map<userId, token>) grow unbounded? Is there eviction?
- The `PlatformTokenResolver` is unused (static mode) — is it still being instantiated?

**Files**: `src/auth/platform-jwt-provider.ts`, `src/auth/platform-token-resolver.ts`

### 3. Audit Server Factory

Review the `serverFactory` callback for optimization opportunities.

**Questions to answer**:
- What does `createRememberServer()` actually do on each call? (Read remember-mcp source)
- Does it create a new Weaviate client or reuse a singleton?
- Does it call `ensureUserCollection()` on every invocation?
- Could we cache server instances by userId (with TTL)?
- What's the ghost mode overhead? Does ghost_owner change the server substantially?

**Files**: `src/index.ts`, remember-mcp's `factory.ts` (upstream reference)

### 4. Audit Cloud Run Configuration

Review deployment config for performance-relevant settings.

**Questions to answer**:
- Is 512Mi memory sufficient or causing GC pressure?
- Would `min-instances=1` eliminate cold starts? Cost tradeoff?
- Is 60s timeout appropriate for long-running MCP sessions?
- Would HTTP/2 improve SSE performance?
- Is the `E2_HIGHCPU_8` build machine necessary or could we use a smaller one?

**Files**: `cloudbuild.yaml`, `Dockerfile`

### 5. Audit Docker Image

Review container for startup time optimizations.

**Questions to answer**:
- Is the two-stage build optimal?
- Are unnecessary files included in the production image?
- Would a distroless base image reduce startup time?
- Is `npm ci --omit=dev` leaving any unnecessary packages?
- Would pre-warming (loading modules at import time vs lazily) help?

**Files**: `Dockerfile`, `.dockerignore`

### 6. Audit SSE/Transport Layer

Review mcp-auth's transport configuration for optimization opportunities.

**Questions to answer**:
- Is rate limiting (100 req/hr) too aggressive for normal usage?
- Does CORS pre-flight add meaningful latency?
- Is the SSE keepalive interval appropriate?
- Would Streamable HTTP (new MCP transport) be faster than SSE?

**Files**: `src/index.ts` (transport config)

### 7. Compile Findings

Create a prioritized list of enhancements.

**Output format**:
```markdown
| Priority | Enhancement | Expected Impact | Effort | Location |
|----------|-------------|-----------------|--------|----------|
| P0       | ...         | ...             | ...    | ...      |
| P1       | ...         | ...             | ...    | ...      |
| P2       | ...         | ...             | ...    | ...      |
```

Each enhancement should note:
- Whether it's in this project vs upstream (only include this-project items)
- Expected latency reduction
- Risk / breaking change potential
- Whether it requires a new task

---

## Verification

- [ ] Request lifecycle profiled with timing data
- [ ] Auth layer audited — cache TTL, key efficiency, memory growth
- [ ] Server factory audited — creation cost, caching opportunity
- [ ] Cloud Run config reviewed — memory, instances, timeout
- [ ] Docker image reviewed — size, startup, unnecessary deps
- [ ] Transport layer reviewed — rate limits, CORS, keepalive
- [ ] Prioritized enhancement list produced
- [ ] Each enhancement has estimated impact and effort
- [ ] Upstream items noted but excluded from this-project scope

---

## Expected Output

**Files Created**:
- `agent/reports/performance-audit.md` — Full findings and prioritized enhancement list

**Files Modified**:
- `agent/progress.yaml` — Task status updated
- `agent/milestones/milestone-5-performance.md` — Updated with follow-up tasks

**Follow-up**:
- One new task per P0/P1 enhancement identified
- Tasks added to M5 milestone

---

## Notes

- Focus on this wrapper project, not upstream (remember-mcp, remember-core, mcp-auth)
- Upstream findings should be noted but tracked in their respective projects
- Task 63 in remember-core (Weaviate collection pooling) already addresses one upstream bottleneck
- The server is currently working — don't break anything in pursuit of optimization
- Collect data before optimizing — measure first, then prioritize

---

**Next Task**: TBD (based on findings)
**Related**: remember-core task-63 (Weaviate collection pool)
