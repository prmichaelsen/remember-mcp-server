# Task 23: Apply P0/P1 Config Fixes

**Milestone**: [M5 - Performance Optimization](../milestones/milestone-5-performance.md)
**Estimated Time**: 0.5 hours
**Dependencies**: Task 22 (audit)
**Status**: Completed

---

## Objective

Apply the three highest-impact config changes identified in the performance audit.

---

## Changes

### 1. Rate limit: 100/hr → 1000/hr

**File**: `src/index.ts` line 75
**Reason**: 100 req/hr is too restrictive for normal MCP usage. A single Claude session can issue 10-30 tool calls in minutes.

### 2. Cloud Run min-instances: 0 → 1

**File**: `cloudbuild.yaml` line 33
**Reason**: Eliminates 2-5s cold start latency on first request after idle.
**Cost**: ~$2-4/month (memory-only billing for idle instance with default CPU allocation mode: 512Mi × $0.0000025/GiB-sec × 2.6M sec/month ≈ $3.24, minus free tier).

### 3. Cloud Run timeout: 60s → 300s

**File**: `cloudbuild.yaml` line 37
**Reason**: MCP tool calls can be slow (large Weaviate searches, ghost mode Firestore reads). 60s is too aggressive.

---

## Verification

- [x] Rate limit changed from 100 to 1000 in src/index.ts
- [x] min-instances changed from 0 to 1 in cloudbuild.yaml
- [x] timeout changed from 60s to 300s in cloudbuild.yaml
- [x] Type-check passes (`npm run type-check`)
