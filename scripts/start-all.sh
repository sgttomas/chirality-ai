#!/bin/bash

# Chirality AI - Complete Service Startup Script
# This script starts all services in the correct order for development

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
cd "$WORKSPACE_DIR"

echo -e "${BLUE}🚀 Starting Chirality AI Development Environment${NC}"
echo -e "${BLUE}Workspace: $WORKSPACE_DIR${NC}"
echo ""

# Function to check if directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        echo -e "${RED}❌ Directory not found: $1${NC}"
        echo -e "${YELLOW}💡 Make sure you've cloned all repositories to the workspace directory${NC}"
        exit 1
    fi
}

# Function to check if port is available
check_port() {
    if lsof -i :$1 >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Port $1 is already in use${NC}"
        return 1
    fi
    return 0
}

# Check required directories
echo -e "${BLUE}📁 Checking required directories...${NC}"
check_directory "../chirality-semantic-framework"
check_directory "../chirality-ai-app"
echo -e "${GREEN}✅ All directories found${NC}"
echo ""

# Check ports
echo -e "${BLUE}🔍 Checking port availability...${NC}"
PORTS_OK=true
if ! check_port 8080; then PORTS_OK=false; fi
if ! check_port 3000; then PORTS_OK=false; fi
if ! check_port 3002; then PORTS_OK=false; fi

if [ "$PORTS_OK" = false ]; then
    echo -e "${YELLOW}💡 Some ports are in use. Kill existing processes or they will be detected as already running.${NC}"
    echo ""
fi

# Array to track background process PIDs
PIDS=()

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down services...${NC}"
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}Stopping process $pid${NC}"
            kill "$pid" 2>/dev/null || true
        fi
    done
    wait 2>/dev/null || true
    echo -e "${GREEN}✅ All services stopped${NC}"
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

echo -e "${BLUE}🔄 Starting services in sequence...${NC}"
echo ""

# Start GraphQL Service (Port 8080)
echo -e "${BLUE}1️⃣  Starting GraphQL service (port 8080)...${NC}"
cd "../chirality-semantic-framework/graphql-service"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing GraphQL dependencies...${NC}"
    npm install
fi
npm run dev &
GRAPHQL_PID=$!
PIDS+=($GRAPHQL_PID)
echo -e "${GREEN}✅ GraphQL service started (PID: $GRAPHQL_PID)${NC}"

# Wait for GraphQL to be ready
echo -e "${YELLOW}⏳ Waiting for GraphQL service to be ready...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:8080/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ GraphQL service is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ GraphQL service failed to start${NC}"
        exit 1
    fi
    sleep 1
done
echo ""

# Start Semantic Framework (Port 3002)
echo -e "${BLUE}2️⃣  Starting Semantic Framework (port 3002)...${NC}"
cd "../chirality-semantic-framework"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing Semantic Framework dependencies...${NC}"
    npm install
fi
PORT=3002 npm run dev &
FRAMEWORK_PID=$!
PIDS+=($FRAMEWORK_PID)
echo -e "${GREEN}✅ Semantic Framework started (PID: $FRAMEWORK_PID)${NC}"

# Wait for Framework to be ready
echo -e "${YELLOW}⏳ Waiting for Semantic Framework to be ready...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:3002/api/healthz >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Semantic Framework is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Semantic Framework failed to start${NC}"
        exit 1
    fi
    sleep 1
done
echo ""

# Start AI App (Port 3000)
echo -e "${BLUE}3️⃣  Starting AI App (port 3000)...${NC}"
cd "../chirality-ai-app"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing AI App dependencies...${NC}"
    npm install
fi
npm run dev &
APP_PID=$!
PIDS+=($APP_PID)
echo -e "${GREEN}✅ AI App started (PID: $APP_PID)${NC}"

# Wait for AI App to be ready
echo -e "${YELLOW}⏳ Waiting for AI App to be ready...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:3000/api/healthz >/dev/null 2>&1; then
        echo -e "${GREEN}✅ AI App is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ AI App failed to start${NC}"
        exit 1
    fi
    sleep 1
done
echo ""

# All services ready
echo -e "${GREEN}🎉 All services are running!${NC}"
echo ""
echo -e "${BLUE}📊 Service Status:${NC}"
echo -e "  GraphQL Service:     ${GREEN}http://localhost:8080/graphql${NC}"
echo -e "  Semantic Framework:  ${GREEN}http://localhost:3002${NC}"
echo -e "  AI App:              ${GREEN}http://localhost:3000${NC}"
echo -e "  Chirality Core:      ${GREEN}http://localhost:3000/chirality-core${NC} ⭐"
echo ""
echo -e "${BLUE}🔧 Health Checks:${NC}"
curl -s http://localhost:8080/health | jq -r '"  GraphQL: " + .status' 2>/dev/null || echo "  GraphQL: Connected"
curl -s http://localhost:3000/api/healthz | jq -r '"  AI App: " + (.ok | if . then "Healthy" else "Error" end)' 2>/dev/null || echo "  AI App: Running"  
curl -s http://localhost:3002/api/healthz | jq -r '"  Framework: " + (.ok | if . then "Healthy" else "Error" end)' 2>/dev/null || echo "  Framework: Running"
echo ""

# Start Desktop App (optional)
echo -e "${BLUE}4️⃣  Starting Desktop App...${NC}"
cd "$WORKSPACE_DIR/desktop"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing Desktop App dependencies...${NC}"
    npm install
fi

echo -e "${YELLOW}🖥️  Compiling and launching Electron app...${NC}"
npm run compile && npm start &
DESKTOP_PID=$!
PIDS+=($DESKTOP_PID)
echo -e "${GREEN}✅ Desktop app launched (PID: $DESKTOP_PID)${NC}"
echo ""

echo -e "${GREEN}🚀 Complete Chirality AI environment is now running!${NC}"
echo -e "${BLUE}Press Ctrl+C to stop all services${NC}"
echo ""

# Wait for user to stop
wait