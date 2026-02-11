# Remember MCP Server - Requirements

**Concept**: Multi-tenant MCP server wrapping remember-mcp with Platform JWT authentication
**Created**: 2026-02-11
**Status**: Design Specification

---

## Overview

This project wraps the remember-mcp server (a memory/note-taking MCP server) with mcp-auth to enable multi-tenant operation with Platform JWT authentication, integrating with agentbase.me platform.

## Problem Statement

The base remember-mcp server:
- Operates as a single-user service
- Has no authentication mechanism
- Cannot be used in a multi-tenant platform
- Requires direct access to storage backend

We need to:
- Add Platform JWT authentication
- Enable multi-tenant operation (per-user memory isolation)
- Integrate with agentbase.me credentials API
- Deploy as a Cloud Run service

## Core Requirements

### Functional Requirements

1. **Multi-Tenant Memory Storage**
   - Each user has isolated memory/notes
   - User identification via Platform JWT
   - No cross-user data access

2. **Platform JWT Authentication**
   - Validate JWTs issued by agentbase.me
   - Extract userId from JWT claims
   - Cache authentication results (60s TTL)

3. **Credentials Management**
   - Fetch user-specific credentials from agentbase.me
   - Forward JWT to credentials API
   - Cache credentials (5min TTL)
   - Handle missing credentials gracefully

4. **MCP Tool Naming**
   - All tools must follow `remember_{tool_name}` convention
   - Examples: `remember_store`, `remember_recall`, `remember_list`

5. **Storage Backend**
   - Support per-user storage isolation
   - Likely file-based or database-backed
   - Configurable storage location

### Non-Functional Requirements

1. **Performance**
   - Response time < 500ms for cached auth
   - Response time < 2s for credential fetch
   - Support 100 req/hour per user

2. **Reliability**
   - 99.9% uptime
   - Graceful degradation on platform API failures
   - Health check endpoint

3. **Security**
   - JWT validation with shared secret
   - No credential storage in MCP server
   - User data isolation
   - HTTPS only in production

4. **Scalability**
   - Stateless server design
   - Horizontal scaling via Cloud Run
   - 0-10 instances auto-scaling

## Technical Constraints

1. **Base Server Requirements**
   - remember-mcp must export a server factory function
   - Factory signature: `createRememberServer(accessToken: string, userId: string): Server`
   - Tools must be prefixed with `remember_`

2. **Platform Integration**
   - Platform URL: https://agentbase.me
   - JWT issuer: `agentbase.me`
   - JWT audience: `mcp-server`
   - Credentials API: `GET /api/credentials/remember`

3. **Deployment**
   - Google Cloud Run
   - Region: us-central1
   - Container-based deployment
   - Environment variables for configuration

## Success Criteria

- [ ] Server validates Platform JWTs correctly
- [ ] Each user has isolated memory storage
- [ ] Tools follow `remember_*` naming convention
- [ ] Server integrates with agentbase.me credentials API
- [ ] Deployed to Cloud Run with health checks
- [ ] Documentation complete (README, API docs)
- [ ] Local testing works with mock JWT
- [ ] Production testing works with real platform

## Dependencies

### External Projects
- `/home/prmichaelsen/remember-mcp` - Base MCP server (needs factory export)
- `/home/prmichaelsen/mcp-auth` - Auth wrapper library
- `/home/prmichaelsen/agentbase.me` - Platform for credentials API

### NPM Packages
- `@modelcontextprotocol/sdk` - MCP SDK
- `@prmichaelsen/mcp-auth` - Auth wrapper
- `@prmichaelsen/remember-mcp` - Base server (to be published)
- `jsonwebtoken` - JWT validation

## Out of Scope

- ❌ Building the base remember-mcp server (separate project)
- ❌ Modifying the agentbase.me platform
- ❌ Creating new authentication mechanisms
- ❌ Supporting non-JWT authentication
- ❌ Building a web UI

## References

- [Bootstrap Pattern](../patterns/bootstrap.md) - Implementation pattern
- [References](../references.md) - Related projects
- [mcp-auth Documentation](https://github.com/prmichaelsen/mcp-auth)

---

**Status**: Design Specification
**Recommendation**: Proceed with Milestone 1 - Project Setup
