# Task 15: Deploy to Cloud Run

**Milestone**: Milestone 4 - Deployment and Testing
**Estimated Time**: 1 hour
**Dependencies**: Task 14
**Status**: Not Started

---

## Objective

Deploy the remember-mcp-server to Google Cloud Run for production use.

## Steps

1. **Set up Google Cloud project**
   - Ensure gcloud CLI is installed and configured
   - Set project ID
   - Enable required APIs (Cloud Run, Container Registry)

2. **Generate service token**
   ```bash
   SERVICE_TOKEN=$(node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))")
   echo "Service Token: $SERVICE_TOKEN"
   ```

3. **Create secret in Secret Manager**
   ```bash
   echo -n "$SERVICE_TOKEN" | gcloud secrets create platform-service-token --data-file=-
   ```

4. **Build and push Docker image**
   ```bash
   docker build -t gcr.io/YOUR_PROJECT/remember-mcp-server:latest .
   docker push gcr.io/YOUR_PROJECT/remember-mcp-server:latest
   ```

5. **Deploy to Cloud Run**
   ```bash
   gcloud run deploy remember-mcp-server \
     --image gcr.io/YOUR_PROJECT/remember-mcp-server:latest \
     --region us-central1 \
     --allow-unauthenticated \
     --set-env-vars="PLATFORM_URL=https://agentbase.me,NODE_ENV=production" \
     --update-secrets=PLATFORM_SERVICE_TOKEN=platform-service-token:latest \
     --min-instances=0 \
     --max-instances=10 \
     --memory=512Mi \
     --cpu=1
   ```

6. **Get service URL**
   ```bash
   gcloud run services describe remember-mcp-server --region us-central1 --format='value(status.url)'
   ```

7. **Test deployed service**
   - Test health check endpoint
   - Test with Platform JWT
   - Verify tools work correctly

## Verification

- [ ] Docker image pushed to GCR
- [ ] Secret created in Secret Manager
- [ ] Cloud Run service deployed
- [ ] Service is accessible via HTTPS
- [ ] Health check responds
- [ ] Authentication works
- [ ] Tools execute correctly
- [ ] Auto-scaling configured

---

**Next Task**: [Task 16: Production Testing](task-16-production-testing.md)
