# Chirality AI — Developer Setup Guide

This guide gets you from zero to a working Chirality AI dev environment on macOS, following the simple → complex plan:
- **Step 1**: Dockerized backend (Neo4j, GraphQL/Gateway, Admin/Orchestrator)
- **Step 2**: Local frontend (Next.js) for fast iteration
- **Step 3**: Optional Electron wrapper to orchestrate Docker and open the app with one click

---

## 0) Prerequisites (macOS)

Install dependencies:

```bash
# Docker Desktop (required)
# Install from https://www.docker.com/products/docker-desktop/
# After install, open Docker Desktop at least once so the daemon is running.

# Node.js 20.x (recommended)
brew install nvm
mkdir -p ~/.nvm
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc
source ~/.zshrc
nvm install 20
nvm use 20

# Optional but useful
brew install jq wget
```

---

## 1) Project Structure

**Monorepo Structure** - This repository contains both frontend and backend:

```
chirality-ai/                    # This repository
├── frontend/                    # Next.js application (product app)
│   ├── src/                    # React components and pages
│   ├── package.json            # Frontend dependencies
│   └── README.md               # Frontend documentation
├── backend/                     # GraphQL + Admin services
│   ├── graphql/                # GraphQL service with Neo4j integration
│   └── admin/                  # Admin/Orchestrator service with Python CLI wrapper
├── compose/                     # Docker Compose orchestration
│   └── docker-compose.yml      # Backend services definition
├── desktop/                     # Electron desktop wrapper
├── scripts/chirality           # Helper script for Docker operations
└── .env.example                # Environment template
```

---

## 2) Configure environment variables

```bash
# From the root of this repository
cp .env.example .env
open -e .env
```

Set at least:

```env
OPENAI_API_KEY=sk-...           # Your OpenAI key
NEO4J_PASSWORD=<strong_pw>      # Password for Neo4j

# Ports (keep defaults unless needed)
ADMIN_PORT=3001
GRAPHQL_PORT=8080
NEO4J_HTTP_PORT=7474
NEO4J_BOLT_PORT=7687
FRONTEND_PORT=3210
```

This .env is the only place for local ports/keys — both backend and frontend should read from it.

---

## 3) Step 1 — Start the backend in Docker

Make the helper executable (first time only):

```bash
chmod +x ./scripts/chirality
```

Start the stack:

```bash
./scripts/chirality up --build
```

Check endpoints:
- **Admin UI**: http://localhost:3001
- **GraphQL**: http://localhost:8080/graphql
- **Neo4j Browser**: http://localhost:7474 (neo4j / your password)

Stop the stack:

```bash
./scripts/chirality down
```

Other useful commands:

```bash
./scripts/chirality logs
./scripts/chirality status
```

---

## 4) Step 2 — Run the frontend locally

The frontend is located in the `frontend/` directory of this repository:

```bash
cd frontend
npm install
npm run dev     # Development server at http://localhost:3000
# or
npm run build && npm run start   # Production build
```

Frontend should point to:
- `NEXT_PUBLIC_GRAPHQL_URL=http://localhost:8080/graphql`

---

## 5) Health checks

- **Neo4j**: http://localhost:7474 → login works
- **GraphQL**:
  ```bash
  curl -s http://localhost:8080/health
  ```
- **Admin**:
  ```bash
  curl -s http://localhost:3001/api/health
  ```
- **Frontend**: http://localhost:3210 → can call GraphQL

---

## 6) Reset Neo4j data (if needed)

```bash
./scripts/chirality down
docker volume rm chirality_neo4j-data chirality_neo4j-logs
./scripts/chirality up
```

---

## 7) Step 3 — Electron desktop app (optional)

Dev run:

```bash
cd "/Users/ryan/Desktop/ai-env/chirality-ai/desktop"
npm install
npx ts-node src/main.ts
```

- Runs the same docker compose up -d as Step 1
- Opens the frontend when services are ready
- Provides a unified double-click experience

Build installers:

```bash
cd "/Users/ryan/Desktop/ai-env/chirality-ai/desktop"
npm run build
```

---

## 8) What's Dockerized & What's Not

✅ **Dockerized**:
- Neo4j (with plugins, persistence)
- GraphQL/Gateway
- Admin/Orchestrator

🚫 **Not Dockerized** (during dev):
- Next.js frontend
- Electron desktop wrapper

---

## 9) Daily workflow

```bash
# Start backend (from repository root)
./scripts/chirality up

# Start frontend (in separate terminal)
cd frontend
npm run dev

# Stop backend
./scripts/chirality down
```

Or use Electron for double-click startup.

---

## Architecture Overview

### Backend Services (Dockerized)

**Neo4j Database**
- Graph database with APOC plugins
- Persistent volumes for data
- Web interface at :7474

**GraphQL Service** 
- Built with GraphQL Yoga + @neo4j/graphql
- Direct Neo4j integration
- Health checks and logging
- Runs on port 8080

**Admin/Orchestrator Service**
- Express.js API wrapping Python CLI tools
- Orchestrates semantic matrix operations
- Health monitoring and job management
- Runs on port 3001

### Frontend (Local Development)

**Chirality Chat Interface**
- Next.js 15.2.3 with OpenAI Responses API
- Graph-free Chirality Core with document generation
- RAG-enhanced chat with document injection
- Streaming responses with SSE
- Runs on port 3210

### Desktop Application (Optional)

**Electron Wrapper**
- Orchestrates Docker Compose backend
- Launches frontend automatically
- Provides unified double-click experience
- Cross-platform installers (macOS, Windows, Linux)

---

## Key Features

### 🤖 Chirality Document Generation
- **Set Problem**: Define problem statements with initial analysis vectors
- **Generate DS**: Data Template with structured field definitions
- **Generate SP**: Procedural Checklist with step-by-step workflows  
- **Generate X**: Solution Template with narrative solutions
- **Generate M**: Guidance documents with justifications
- **Clear All**: Reset all documents and problem state

### 💬 RAG-Enhanced Chat
- **Document Injection**: All generated documents automatically injected into chat system prompt
- **Citation Support**: References to generated documents with ID tracking
- **Streaming Responses**: Real-time response streaming with robust SSE implementation
- **Command Support**: Natural language commands for document generation

### 🔧 Admin & Developer Tools
- **Admin Dashboard** (`:3001`): Service orchestration and monitoring
- **GraphQL Playground** (`:8080/graphql`): Direct API access
- **Neo4j Browser** (`:7474`): Graph database exploration
- **Health Checks**: Comprehensive service monitoring

---

## Troubleshooting

### Common Issues

**Docker not running** → Compose errors immediately → open Docker Desktop and retry

**Port already in use** (3210/3001/8080/7474) → change the host ports in .env:
```bash
./scripts/chirality down
# Edit .env with new ports
./scripts/chirality up
```

**Apple Silicon images** → ensure your images are arm64 compatible or build locally:
```bash
./scripts/chirality up --build
```

**Neo4j password mismatch** → if you change NEO4J_PASSWORD after first start, reset volumes:
```bash
./scripts/chirality down
docker volume rm chirality_neo4j-data chirality_neo4j-logs
./scripts/chirality up
```

### Debug Commands

```bash
# Check service status
./scripts/chirality status

# Follow all logs
./scripts/chirality logs

# Follow specific service logs
./scripts/chirality logs neo4j
./scripts/chirality logs graphql
./scripts/chirality logs admin

# Test frontend health
curl http://localhost:3210/api/healthz

# Test backend health
curl http://localhost:8080/health
curl http://localhost:3001/api/health
```

---

## Development Notes

### Environment Variables
- Single source of truth: `chirality-ai/.env`
- Frontend reads from its own `.env.local` but should use same ports
- Docker services get env vars via docker-compose.yml

### Service Dependencies
- Neo4j must start first (healthcheck)
- GraphQL depends on Neo4j
- Admin depends on Neo4j + GraphQL
- Frontend is independent but connects to GraphQL

### File Structure
```
chirality-ai/
├── .env.example              # Environment template
├── compose/
│   └── docker-compose.yml    # Backend services
├── scripts/
│   └── chirality             # Helper script
├── desktop/                  # Electron app
│   ├── src/main.ts          # Main Electron process
│   └── package.json         # Electron dependencies
└── README.md                # This file
```

---

This setup provides a robust, scalable development environment that matches production deployment patterns while maintaining the fast iteration cycle needed for active development.

🤖 **Ready to build with the Chirality Framework!**