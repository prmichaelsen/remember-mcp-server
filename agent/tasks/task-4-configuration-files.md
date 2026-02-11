# Task 4: Create Configuration Files

**Milestone**: Milestone 1 - Project Setup
**Estimated Time**: 30 minutes
**Dependencies**: Task 3
**Status**: Not Started

---

## Objective

Create all necessary configuration files for version control, Docker, and environment variables.

## Steps

1. **Create .gitignore**
   - Ignore node_modules/
   - Ignore dist/
   - Ignore .env files
   - Ignore logs
   - Ignore OS files

2. **Create .dockerignore**
   - Ignore development files
   - Ignore git directory
   - Ignore documentation
   - Keep only necessary files for build

3. **Create .env.example**
   - Document all required environment variables
   - Provide example values
   - Add comments explaining each variable

4. **Verify files**
   ```bash
   cat .gitignore .dockerignore .env.example
   ```

## Verification

- [ ] `.gitignore` exists with proper patterns
- [ ] `.dockerignore` exists with proper patterns
- [ ] `.env.example` exists with all variables documented
- [ ] No sensitive data in .env.example
- [ ] Files are properly formatted

## Expected File Contents

### .gitignore
```
# Dependencies
node_modules/

# Build output
dist/
build/

# Environment
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
```

### .dockerignore
```
# Development
node_modules/
dist/
build/

# Git
.git/
.gitignore

# Documentation
*.md
agent/
docs/

# Environment
.env
.env.local
.env.example

# IDE
.vscode/
.idea/

# Logs
*.log

# OS
.DS_Store
```

### .env.example
```env
# Platform JWT Authentication
# Shared secret for validating JWTs issued by agentbase.me
PLATFORM_SERVICE_TOKEN=your-shared-secret-here

# Platform API
# Base URL for agentbase.me platform
PLATFORM_URL=https://agentbase.me

# Server Configuration
# Port for the MCP server to listen on
PORT=8080

# Environment
NODE_ENV=development

# Logging
LOG_LEVEL=info
```

---

**Next Task**: [Task 5: Create README Documentation](task-5-readme-documentation.md)
