# Task 1: Initialize Node.js Project

**Milestone**: Milestone 1 - Project Setup
**Estimated Time**: 30 minutes
**Dependencies**: None
**Status**: Not Started

---

## Objective

Initialize the Node.js project with package.json and install all required dependencies for a multi-tenant MCP server with Platform JWT authentication.

## Steps

1. **Initialize package.json**
   ```bash
   npm init -y
   ```

2. **Update package.json metadata**
   - Set name to `@prmichaelsen/remember-mcp-server`
   - Set version to `1.0.0`
   - Set type to `module` (ES modules)
   - Add description
   - Add author and license

3. **Install production dependencies**
   ```bash
   npm install \
     @modelcontextprotocol/sdk \
     @prmichaelsen/mcp-auth \
     jsonwebtoken
   ```
   
   Note: `@prmichaelsen/remember-mcp` will be added in Milestone 3

4. **Install development dependencies**
   ```bash
   npm install --save-dev \
     typescript \
     @types/node \
     @types/jsonwebtoken \
     tsx
   ```

5. **Add npm scripts to package.json**
   - `build`: TypeScript compilation
   - `dev`: Development mode with hot reload
   - `start`: Production start
   - `type-check`: TypeScript type checking

## Verification

- [ ] `package.json` exists with correct metadata
- [ ] `package.json` has `"type": "module"`
- [ ] All dependencies are installed (check `node_modules/`)
- [ ] `package-lock.json` is created
- [ ] No installation errors or warnings
- [ ] Scripts are defined in package.json

## Expected package.json Structure

```json
{
  "name": "@prmichaelsen/remember-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "description": "Multi-tenant MCP server for remember-mcp with Platform JWT authentication",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "dev": "tsx watch src/index.ts",
    "start": "node dist/index.js",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4",
    "@prmichaelsen/mcp-auth": "^4.0.0",
    "jsonwebtoken": "^9.0.2"
  },
  "devDependencies": {
    "@types/node": "^22.10.2",
    "@types/jsonwebtoken": "^9.0.5",
    "tsx": "^4.7.0",
    "typescript": "^5.7.2"
  }
}
```

---

**Next Task**: [Task 2: Create TypeScript Configuration](task-2-typescript-config.md)
