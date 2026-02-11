# Remember MCP Server

Multi-tenant MCP server wrapping remember-mcp with Platform JWT authentication for agentbase.me.

## Overview

This server wraps the [remember-mcp](https://github.com/prmichaelsen/remember-mcp) server with authentication and multi-tenancy support, enabling it to be used in the agentbase.me platform.

### Features

- 🔐 Platform JWT authentication
- 👥 Multi-tenant operation with per-user memory isolation
- 🔄 Automatic credential resolution via platform API
- 📦 Containerized deployment to Cloud Run
- ⚡ Caching for performance
- 🏥 Health check endpoint

### Architecture

```
Client (Platform JWT)
  ↓
Platform JWT Provider (validates JWT → userId)
  ↓
Platform Token Resolver (userId → credentials via platform API)
  ↓
Remember MCP Server (executes memory tools)
  ↓
User Storage (isolated per user)
```

## Prerequisites

- Node.js 20+
- npm or yarn
- Docker (for containerization)
- Google Cloud account (for deployment)
- Access to agentbase.me platform

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/prmichaelsen/remember-mcp-server.git
   cd remember-mcp-server
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

## Usage

### Development Mode

```bash
npm run dev
```

Server will start on `http://localhost:8080` with hot reload enabled.

### Production Mode

```bash
npm run build
npm start
```

### Testing

```bash
# Health check
curl http://localhost:8080/mcp/health

# List tools (requires Platform JWT)
curl -X POST http://localhost:8080/mcp/message \
  -H "Authorization: Bearer <platform-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `PLATFORM_SERVICE_TOKEN` | Shared secret for JWT validation | Yes | - |
| `PLATFORM_URL` | Platform API base URL | Yes | - |
| `PORT` | Server port | No | 8080 |
| `NODE_ENV` | Environment (development/production) | No | development |
| `LOG_LEVEL` | Logging level | No | info |

### Platform Integration

This server integrates with agentbase.me platform:

1. **Authentication**: Validates JWTs issued by platform
2. **Credentials**: Fetches user credentials from platform API
3. **Storage**: Isolates user data based on userId from JWT

## Development

### Project Structure

```
remember-mcp-server/
├── src/
│   ├── index.ts                      # Main server
│   └── auth/
│       ├── platform-jwt-provider.ts  # JWT authentication
│       └── platform-token-resolver.ts # Credential resolution
├── agent/                            # Agent Context Protocol docs
├── package.json
├── tsconfig.json
├── Dockerfile
└── README.md
```

### Build Process

```bash
# Type check
npm run type-check

# Build
npm run build

# Output in dist/
```

## Deployment

### Docker

```bash
# Build image
docker build -t remember-mcp-server .

# Run container
docker run -p 8080:8080 \
  -e PLATFORM_SERVICE_TOKEN=your-token \
  -e PLATFORM_URL=https://agentbase.me \
  remember-mcp-server
```

### Google Cloud Run

```bash
# Build and push
docker build -t gcr.io/YOUR_PROJECT/remember-mcp-server .
docker push gcr.io/YOUR_PROJECT/remember-mcp-server

# Deploy
gcloud run deploy remember-mcp-server \
  --image gcr.io/YOUR_PROJECT/remember-mcp-server \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars="PLATFORM_URL=https://agentbase.me" \
  --update-secrets=PLATFORM_SERVICE_TOKEN=platform-service-token:latest
```

## Related Projects

- [remember-mcp](https://github.com/prmichaelsen/remember-mcp) - Base MCP server
- [mcp-auth](https://github.com/prmichaelsen/mcp-auth) - Authentication wrapper library
- [agentbase.me](https://github.com/prmichaelsen/agentbase.me) - Platform for multi-tenant MCP servers

## License

MIT

## Author

Patrick Michaelsen ([@prmichaelsen](https://github.com/prmichaelsen))
