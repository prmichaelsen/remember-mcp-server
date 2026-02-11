# Task 14: Test Docker Locally

**Milestone**: Milestone 4 - Deployment and Testing
**Estimated Time**: 30 minutes
**Dependencies**: Task 13
**Status**: Not Started

---

## Objective

Build and test the Docker container locally to ensure it works correctly before deploying to Cloud Run.

## Steps

1. **Build Docker image**
   ```bash
   docker build -t remember-mcp-server:latest .
   ```

2. **Check image size**
   ```bash
   docker images remember-mcp-server:latest
   ```

3. **Run container locally**
   ```bash
   docker run -p 8080:8080 \
     -e PLATFORM_SERVICE_TOKEN=test-token \
     -e PLATFORM_URL=https://agentbase.me \
     remember-mcp-server:latest
   ```

4. **Test health check**
   ```bash
   curl http://localhost:8080/mcp/health
   ```

5. **Test with JWT**
   - Generate test JWT
   - Test tool listing
   - Verify server responds correctly

6. **Check logs**
   - Verify no errors in container logs
   - Check startup messages
   - Confirm server is listening

## Verification

- [ ] Docker image builds successfully
- [ ] Image size is reasonable (<500MB)
- [ ] Container starts without errors
- [ ] Health check endpoint responds
- [ ] Server accepts JWT authentication
- [ ] Tools are listed correctly
- [ ] No errors in logs

---

**Next Task**: [Task 15: Deploy to Cloud Run](task-15-deploy-cloudrun.md)
