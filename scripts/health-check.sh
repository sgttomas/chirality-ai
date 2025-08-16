#!/bin/bash

# Chirality AI - Health Check Script
# Quick verification that all services are running correctly

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏥 Chirality AI Health Check${NC}"
echo ""

# Function to check HTTP endpoint
check_endpoint() {
    local url=$1
    local name=$2
    local expected_code=${3:-200}
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$http_code" = "$expected_code" ]; then
        echo -e "  ${GREEN}✅ $name${NC} - HTTP $http_code"
        return 0
    else
        echo -e "  ${RED}❌ $name${NC} - HTTP $http_code (expected $expected_code)"
        return 1
    fi
}

# Function to check if port is listening
check_port() {
    local port=$1
    local name=$2
    
    if lsof -i :$port >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ $name${NC} - Port $port is listening"
        return 0
    else
        echo -e "  ${RED}❌ $name${NC} - Port $port is not listening"
        return 1
    fi
}

# Check ports first
echo -e "${BLUE}🔍 Checking ports:${NC}"
check_port 8080 "GraphQL Service"
check_port 3000 "AI App"
check_port 3002 "Semantic Framework"
echo ""

# Check HTTP endpoints
echo -e "${BLUE}🌐 Checking HTTP endpoints:${NC}"
check_endpoint "http://localhost:8080/health" "GraphQL Health"
check_endpoint "http://localhost:3000/api/healthz" "AI App Health"
check_endpoint "http://localhost:3002/api/healthz" "Framework Health"
check_endpoint "http://localhost:3000/chirality-core" "Chirality Core Page"
echo ""

# Check GraphQL functionality
echo -e "${BLUE}🔧 Testing GraphQL query:${NC}"
graphql_response=$(curl -s -X POST http://localhost:8080/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __typename }"}' 2>/dev/null)

if echo "$graphql_response" | grep -q '"__typename".*"Query"'; then
    echo -e "  ${GREEN}✅ GraphQL Query${NC} - Working correctly"
else
    echo -e "  ${RED}❌ GraphQL Query${NC} - Failed or unexpected response"
    echo -e "    Response: $graphql_response"
fi
echo ""

# Service details
echo -e "${BLUE}📊 Service Details:${NC}"

# GraphQL service details
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    graphql_health=$(curl -s http://localhost:8080/health 2>/dev/null)
    echo -e "  ${BLUE}GraphQL:${NC} $graphql_health"
fi

# AI App details  
if curl -s http://localhost:3000/api/healthz >/dev/null 2>&1; then
    app_health=$(curl -s http://localhost:3000/api/healthz 2>/dev/null)
    echo -e "  ${BLUE}AI App:${NC} $app_health"
fi

# Framework details
if curl -s http://localhost:3002/api/healthz >/dev/null 2>&1; then
    framework_health=$(curl -s http://localhost:3002/api/healthz 2>/dev/null)
    echo -e "  ${BLUE}Framework:${NC} $framework_health"
fi

echo ""

# Desktop app check
echo -e "${BLUE}🖥️  Desktop App:${NC}"
desktop_processes=$(pgrep -f "electron.*chirality" | wc -l)
if [ "$desktop_processes" -gt 0 ]; then
    echo -e "  ${GREEN}✅ Desktop App${NC} - $desktop_processes Electron process(es) running"
else
    echo -e "  ${YELLOW}⚠️  Desktop App${NC} - No Electron processes detected"
fi
echo ""

# Environment check
echo -e "${BLUE}🔧 Environment:${NC}"
if [ -f "../chirality-ai-app/.env.local" ]; then
    if grep -q "OPENAI_API_KEY" "../chirality-ai-app/.env.local" 2>/dev/null; then
        echo -e "  ${GREEN}✅ OpenAI API Key${NC} - Configured in chirality-ai-app"
    else
        echo -e "  ${YELLOW}⚠️  OpenAI API Key${NC} - Not found in chirality-ai-app/.env.local"
    fi
else
    echo -e "  ${RED}❌ Environment${NC} - chirality-ai-app/.env.local not found"
fi

# Summary
echo ""
echo -e "${BLUE}📋 Quick Access URLs:${NC}"
echo -e "  • GraphQL Playground: ${GREEN}http://localhost:8080/graphql${NC}"
echo -e "  • AI App:             ${GREEN}http://localhost:3000${NC}"
echo -e "  • Chirality Core:     ${GREEN}http://localhost:3000/chirality-core${NC} ⭐"
echo -e "  • Semantic Framework: ${GREEN}http://localhost:3002${NC}"
echo -e "  • Chat Admin:         ${GREEN}http://localhost:3000/chat-admin${NC}"
echo ""
echo -e "${GREEN}🎉 Health check complete!${NC}"