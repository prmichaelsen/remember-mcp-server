# Task 13: Create Dockerfile

**Milestone**: Milestone 4 - Deployment and Testing
**Estimated Time**: 1 hour
**Dependencies**: Task 12
**Status**: Not Started

---

## Objective

Create a multi-stage Dockerfile for building and running the remember-mcp-server in production.

## Steps

1. **Create multi-stage Dockerfile**
   - Builder stage: Install dependencies and compile TypeScript
   - Production stage: Copy built files and production dependencies only

2. **Optimize image size**
   - Use node:20-alpine base image
   - Only copy necessary files
   - Use .dockerignore to exclude unnecessary files

3. **Add health check**
   - Configure Docker HEALTHCHECK
   - Point to /mcp/health endpoint

4. **Set proper permissions**
   - Run as non-root user
   - Set working directory

5. **Configure environment**
   - Expose port 8080
   - Set NODE_ENV=production
   - Document required environment variables

## Verification

- [ ] Dockerfile exists in project root
- [ ] Multi-stage build configured
- [ ] Health check configured
- [ ] Runs as non-root user
- [ ] Image builds successfully
- [ ] Image size is reasonable (<500MB)

## Expected Dockerfile

See [`agent/patterns/bootstrap.md`](../patterns/bootstrap.md) Step 9 for complete Dockerfile example.

---

**Next Task**: [Task 14: Test Docker Locally](task-14-test-docker.md)
