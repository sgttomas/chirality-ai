# Chirality AI: Meta-Learning Framework Monorepo

## 🧠 The Chirality Framework

This monorepo implements the **Chirality Framework** - a meta-ontological methodology for generating reliable knowledge about generating reliable knowledge. The framework operates through systematic **12-station semantic valley progression** and has been validated through self-referential implementation.

### Core Framework Principles

**Meta-Learning Methodology**
The Chirality Framework progresses through a 12-station semantic valley:
Problem Statement → Requirements → Objectives → Output → Verification → Validation → Evaluation → Assessment → Implementation → Instantiation → Reflection → Resolution

**Self-Referential Validation**
This implementation proves the framework's effectiveness by applying it to the meta-problem of "generating reliable knowledge" - successfully using the methodology to validate the methodology itself.

**LLM as Semantic Interpolation Engine**
Large Language Models serve exclusively as **semantic interpolation engines** that resolve abstract word pairings into coherent concepts through semantic multiplication (`*`), while the framework maintains strict separation between constructive operations (human-designed) and generative operations (LLM-resolved).

## 🏗️ Production Application Orchestrator

This repository serves as the **production application orchestrator** for the Chirality Framework ecosystem. It demonstrates how all framework components integrate to create a complete meta-learning system.

### Component Architecture

**🔄 Complete Framework Ecosystem:**
- **[Chirality-Framework](https://github.com/sgttomas/Chirality-Framework)**: Core semantic engine + backend services
- **[Chirality-chat](https://github.com/sgttomas/Chirality-chat)**: Modern chat interfaces (2 variants)
- **This Repository**: Production orchestration + desktop packaging

### How Components Work Together

1. **Backend Services** (from Chirality-Framework)
   - GraphQL service provides semantic matrix operations
   - Admin service orchestrates CLI tools and processes
   - Neo4j database persists semantic valley progression

2. **Frontend Applications** (from Chirality-chat)
   - Chat interfaces provide conversational access to framework
   - LLMs perform semantic interpolation within framework constraints
   - Real-time document generation and RAG integration

3. **Production Orchestration** (this repository)
   - Docker Compose configuration for unified deployment
   - Electron desktop wrapper for one-click experience
   - Development environment for integrated testing

## 🚀 Quick Production Setup

### Single-Command Deployment
```bash
# Start complete production stack
docker compose up -d

# Access applications:
# - Chat Interface: http://localhost:3000
# - GraphQL API: http://localhost:8080/graphql
# - Admin Dashboard: http://localhost:3001
# - Neo4j Browser: http://localhost:7474
```

### Desktop Application (One-Click Experience)
```bash
cd desktop
npm install
npm run build    # Creates platform-specific installers
npm run dev      # Development mode with auto-orchestration
```

## 🚀 Developer Setup Guide

For development across the ecosystem:
- **Step 1**: Backend services via Docker Compose
- **Step 2**: Frontend development servers for iteration
- **Step 3**: Desktop packaging for distribution

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

### Split-Apps Architecture

This monorepo demonstrates the framework's **Split-Apps Architecture**, separating concerns between semantic operations and user interfaces:

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

## 📚 Framework Documentation

- **[Chirality-Framework](https://github.com/sgttomas/Chirality-Framework)**: Core semantic engine and GraphQL service
- **[Chirality-chat](https://github.com/sgttomas/Chirality-chat)**: Modern chat interface implementation
- **[Chirality-ai-app](https://github.com/sgttomas/Chirality-ai-app)**: Production application interface

## 🤝 Contributing

This project implements a **reasoning compiler** that systematically generates reliable knowledge across arbitrary domains. Contributions should maintain the framework's meta-learning integrity and respect the boundary between constructive (human-designed) and generative (LLM-resolved) operations.

---

*This monorepo demonstrates the Chirality Framework's ability to bridge human meta-cognition with AI semantic interpolation capabilities, contributing to the advancement of AI reasoning methodology and knowledge generation systems.*

🤖 **Ready to build with the Chirality Framework!**