#!/bin/bash
# MCP Auth Server Base - Validation Script
# Validates MCP auth server project configuration, dependencies, and structure
# Version: 1.0.0

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
if [ -f "${SCRIPT_DIR}/acp.common.sh" ]; then
  . "${SCRIPT_DIR}/acp.common.sh"
  init_colors
else
  # Fallback colors if acp.common.sh not available
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
  BOLD='\033[1m'
fi

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Validation level (quick, standard, full)
VALIDATION_LEVEL="${1:-quick}"

# Options
SKIP_TESTS=false
SKIP_DOCKER=false
VERBOSE=false
FIX=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --level)
      VALIDATION_LEVEL="$2"
      shift 2
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --skip-docker)
      SKIP_DOCKER=true
      shift
      ;;
    --fix)
      FIX=true
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Validation results arrays
declare -a ERRORS
declare -a WARNINGS
declare -a INFO

# Helper functions
print_header() {
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_section() {
  echo -e "\n${BOLD}$1${NC}"
}

check_pass() {
  ((TOTAL_CHECKS++))
  ((PASSED_CHECKS++))
  echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
  ((TOTAL_CHECKS++))
  ((FAILED_CHECKS++))
  echo -e "${RED}✗${NC} $1"
  ERRORS+=("$1")
}

check_warn() {
  ((TOTAL_CHECKS++))
  ((WARNING_CHECKS++))
  echo -e "${YELLOW}⚠${NC} $1"
  WARNINGS+=("$1")
}

check_info() {
  echo -e "${BLUE}ℹ${NC} $1"
  INFO+=("$1")
}

# Start validation
print_header "🔍 MCP Auth Server Validation"

echo "Project: $(basename "$PWD")"
echo "Validation Level: $VALIDATION_LEVEL"
echo "Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"

# ============================================================================
# Step 1: Validate File Structure
# ============================================================================

print_section "📁 File Structure"

# Core files
if [ -f "package.json" ]; then
  check_pass "package.json exists"
else
  check_fail "package.json missing"
fi

if [ -f "tsconfig.json" ]; then
  check_pass "tsconfig.json exists"
else
  check_fail "tsconfig.json missing"
fi

if [ -f ".gitignore" ]; then
  check_pass ".gitignore exists"
else
  check_fail ".gitignore missing"
fi

if [ -f "README.md" ]; then
  check_pass "README.md exists"
else
  check_warn "README.md missing"
fi

if [ -f "src/index.ts" ]; then
  check_pass "src/index.ts exists"
else
  check_fail "src/index.ts missing"
fi

# Configuration files
if [ -f "jest.config.js" ]; then
  check_pass "jest.config.js exists"
else
  check_info "jest.config.js not found (testing may not be configured)"
fi

if [ -f ".env" ]; then
  check_pass ".env exists"
elif [ -f ".env.example" ]; then
  check_warn ".env missing (found .env.example)"
else
  check_fail ".env and .env.example both missing"
fi

if [ -f ".dockerignore" ]; then
  check_pass ".dockerignore exists"
else
  check_warn ".dockerignore missing"
fi

# Build scripts
if [ -f "scripts/build.js" ]; then
  check_pass "scripts/build.js exists"
else
  check_fail "scripts/build.js missing"
fi

if [ -f "scripts/build-dev.js" ]; then
  check_pass "scripts/build-dev.js exists"
else
  check_warn "scripts/build-dev.js missing"
fi

# Deployment files
if [ -f "Dockerfile.development" ]; then
  check_pass "Dockerfile.development exists"
else
  check_warn "Dockerfile.development missing"
fi

if [ -f "Dockerfile.production" ]; then
  check_pass "Dockerfile.production exists"
else
  check_warn "Dockerfile.production missing"
fi

if [ -f "cloudbuild.yaml" ]; then
  check_pass "cloudbuild.yaml exists"
else
  check_warn "cloudbuild.yaml missing"
fi

# Utility scripts
if [ -f "scripts/upload-secrets.ts" ]; then
  check_pass "scripts/upload-secrets.ts exists"
else
  check_info "scripts/upload-secrets.ts not found"
fi

if [ -f "scripts/test-auth.ts" ]; then
  check_pass "scripts/test-auth.ts exists"
else
  check_info "scripts/test-auth.ts not found"
fi

# Directories
if [ -d "src" ]; then
  check_pass "src/ directory exists"
else
  check_fail "src/ directory missing"
fi

if [ -d "scripts" ]; then
  check_pass "scripts/ directory exists"
else
  check_fail "scripts/ directory missing"
fi

if [ -d "node_modules" ]; then
  check_pass "node_modules/ directory exists"
else
  check_warn "node_modules/ directory missing (run npm install)"
fi

# ============================================================================
# Step 2: Validate Dependencies
# ============================================================================

print_section "📦 Dependencies"

if [ -d "node_modules" ]; then
  check_pass "node_modules/ exists"
  
  # Check lock file
  if [ -f "package-lock.json" ]; then
    check_pass "package-lock.json exists"
  elif [ -f "yarn.lock" ]; then
    check_pass "yarn.lock exists"
  else
    check_warn "No lock file found (package-lock.json or yarn.lock)"
  fi
  
  # Check critical dependencies
  if npm list @modelcontextprotocol/sdk >/dev/null 2>&1; then
    check_pass "@modelcontextprotocol/sdk installed"
  else
    check_fail "@modelcontextprotocol/sdk not installed"
  fi
  
  if npm list @prmichaelsen/mcp-auth >/dev/null 2>&1; then
    check_pass "@prmichaelsen/mcp-auth installed"
  else
    check_fail "@prmichaelsen/mcp-auth not installed"
  fi
  
  if npm list typescript >/dev/null 2>&1; then
    check_pass "typescript installed"
  else
    check_fail "typescript not installed"
  fi
  
  if npm list esbuild >/dev/null 2>&1; then
    check_pass "esbuild installed"
  else
    check_fail "esbuild not installed"
  fi
  
  # Check for version conflicts
  if npm list --depth=0 2>&1 | grep -qi "invalid\|missing"; then
    check_warn "Dependency version conflicts detected"
  else
    check_pass "No dependency conflicts"
  fi
  
else
  check_fail "node_modules/ missing - run npm install"
fi

# Security audit (full validation only)
if [ "$VALIDATION_LEVEL" = "full" ]; then
  print_section "🔒 Security Audit"
  
  if command -v npm >/dev/null 2>&1; then
    AUDIT_OUTPUT=$(npm audit --production --json 2>/dev/null || echo "{}")
    CRITICAL=$(echo "$AUDIT_OUTPUT" | grep -o '"critical":[0-9]*' | cut -d: -f2 || echo "0")
    HIGH=$(echo "$AUDIT_OUTPUT" | grep -o '"high":[0-9]*' | cut -d: -f2 || echo "0")
    
    if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
      check_fail "Found $CRITICAL critical and $HIGH high severity vulnerabilities"
    else
      check_pass "No critical or high severity vulnerabilities"
    fi
  fi
fi

# ============================================================================
# Step 3: Validate Configuration Files
# ============================================================================

print_section "⚙️  Configuration Files"

# Validate package.json
if [ -f "package.json" ]; then
  if node -e "JSON.parse(require('fs').readFileSync('package.json', 'utf8'))" 2>/dev/null; then
    check_pass "package.json has valid JSON syntax"
    
    # Check required fields
    if grep -q '"type".*"module"' package.json; then
      check_pass "package.json has type: module"
    else
      check_fail "package.json missing type: module"
    fi
    
    if grep -q '"@modelcontextprotocol/sdk"' package.json; then
      check_pass "package.json includes @modelcontextprotocol/sdk"
    else
      check_fail "package.json missing @modelcontextprotocol/sdk dependency"
    fi
    
    if grep -q '"@prmichaelsen/mcp-auth"' package.json; then
      check_pass "package.json includes @prmichaelsen/mcp-auth"
    else
      check_fail "package.json missing @prmichaelsen/mcp-auth dependency"
    fi
    
  else
    check_fail "package.json has invalid JSON syntax"
  fi
fi

# Validate tsconfig.json
if [ -f "tsconfig.json" ]; then
  if node -e "JSON.parse(require('fs').readFileSync('tsconfig.json', 'utf8'))" 2>/dev/null; then
    check_pass "tsconfig.json has valid JSON syntax"
    
    # Check required options
    if grep -q '"strict".*true' tsconfig.json; then
      check_pass "tsconfig.json has strict mode enabled"
    else
      check_warn "tsconfig.json strict mode not enabled"
    fi
    
    if grep -q '"esModuleInterop".*true' tsconfig.json; then
      check_pass "tsconfig.json has esModuleInterop enabled"
    else
      check_warn "tsconfig.json missing esModuleInterop"
    fi
    
  else
    check_fail "tsconfig.json has invalid JSON syntax"
  fi
fi

# Validate jest.config.js
if [ -f "jest.config.js" ]; then
  if node -c jest.config.js 2>/dev/null; then
    check_pass "jest.config.js has valid syntax"
  else
    check_fail "jest.config.js has syntax errors"
  fi
fi

# Validate esbuild scripts
if [ -f "scripts/build.js" ]; then
  if node -c scripts/build.js 2>/dev/null; then
    check_pass "scripts/build.js has valid syntax"
    
    if grep -q "esbuild" scripts/build.js; then
      check_pass "scripts/build.js uses esbuild"
    else
      check_warn "scripts/build.js doesn't reference esbuild"
    fi
  else
    check_fail "scripts/build.js has syntax errors"
  fi
fi

# ============================================================================
# Step 4: Validate Environment Variables
# ============================================================================

print_section "🔐 Environment Variables"

if [ -f ".env" ]; then
  check_pass ".env file exists"
  
  # Source .env file (safely)
  set -a
  source .env 2>/dev/null || true
  set +a
  
  # Check required variables
  if [ -n "$PORT" ]; then
    check_pass "PORT is set ($PORT)"
  else
    check_warn "PORT not set (will use default)"
  fi
  
  if [ -n "$NODE_ENV" ]; then
    check_pass "NODE_ENV is set ($NODE_ENV)"
  else
    check_warn "NODE_ENV not set"
  fi
  
  if [ -n "$LOG_LEVEL" ]; then
    check_pass "LOG_LEVEL is set ($LOG_LEVEL)"
  else
    check_warn "LOG_LEVEL not set"
  fi
  
  # Check for placeholders
  if grep -qi "your-.*-here\|placeholder\|changeme" .env 2>/dev/null; then
    check_warn "Placeholder values detected in .env"
  else
    check_pass "No placeholder values in .env"
  fi
  
  # Check .env is in .gitignore
  if [ -f ".gitignore" ] && grep -q "^\.env$" .gitignore; then
    check_pass ".env is in .gitignore"
  else
    check_fail ".env is NOT in .gitignore (security risk!)"
  fi
  
elif [ -f ".env.example" ]; then
  check_warn ".env missing (found .env.example - copy to .env)"
else
  check_fail ".env and .env.example both missing"
fi

# ============================================================================
# Step 5: Validate TypeScript Compilation
# ============================================================================

print_section "📘 TypeScript Compilation"

if [ -d "node_modules" ] && [ -f "tsconfig.json" ]; then
  if npx tsc --noEmit 2>/dev/null; then
    check_pass "TypeScript compiles without errors"
  else
    check_fail "TypeScript compilation failed"
    if [ "$VERBOSE" = true ]; then
      echo -e "\n${RED}TypeScript Errors:${NC}"
      npx tsc --noEmit 2>&1 | head -20
    fi
  fi
else
  check_warn "Skipping TypeScript check (dependencies not installed)"
fi

# ============================================================================
# Step 6: Validate Build Process (Standard/Full)
# ============================================================================

if [ "$VALIDATION_LEVEL" = "standard" ] || [ "$VALIDATION_LEVEL" = "full" ]; then
  print_section "🔨 Build Process"
  
  if [ -d "node_modules" ]; then
    # Clean previous build
    rm -rf dist 2>/dev/null || true
    
    # Run build
    if npm run build >/dev/null 2>&1; then
      check_pass "Build completed successfully"
      
      # Check build artifacts
      if [ -f "dist/index.js" ]; then
        check_pass "dist/index.js created"
        
        # Check file size
        SIZE=$(stat -f%z dist/index.js 2>/dev/null || stat -c%s dist/index.js 2>/dev/null || echo "0")
        if [ "$SIZE" -gt 1000 ]; then
          check_pass "dist/index.js size is reasonable (${SIZE} bytes)"
        else
          check_warn "dist/index.js is very small (${SIZE} bytes)"
        fi
        
        # Validate JavaScript syntax
        if node -c dist/index.js 2>/dev/null; then
          check_pass "dist/index.js has valid syntax"
        else
          check_fail "dist/index.js has syntax errors"
        fi
      else
        check_fail "dist/index.js not created"
      fi
    else
      check_fail "Build failed"
      if [ "$VERBOSE" = true ]; then
        echo -e "\n${RED}Build Errors:${NC}"
        npm run build 2>&1 | tail -20
      fi
    fi
  else
    check_warn "Skipping build check (dependencies not installed)"
  fi
fi

# ============================================================================
# Step 7: Validate Tests (Standard/Full)
# ============================================================================

if [ "$VALIDATION_LEVEL" = "standard" ] || [ "$VALIDATION_LEVEL" = "full" ]; then
  if [ "$SKIP_TESTS" = false ]; then
    print_section "🧪 Tests"
    
    # Check if tests exist
    TEST_COUNT=$(find src -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | wc -l)
    
    if [ "$TEST_COUNT" -gt 0 ]; then
      check_pass "Found $TEST_COUNT test files"
      
      if [ -d "node_modules" ] && [ -f "jest.config.js" ]; then
        # Run tests
        if npm test -- --passWithNoTests >/dev/null 2>&1; then
          check_pass "All tests passed"
        else
          check_fail "Tests failed"
          if [ "$VERBOSE" = true ]; then
            echo -e "\n${RED}Test Failures:${NC}"
            npm test 2>&1 | tail -30
          fi
        fi
      else
        check_warn "Skipping test execution (jest not configured)"
      fi
    else
      check_info "No test files found"
    fi
  else
    check_info "Skipping tests (--skip-tests flag)"
  fi
fi

# ============================================================================
# Step 8: Validate Authentication Configuration
# ============================================================================

print_section "🔑 Authentication Configuration"

if [ -f "src/index.ts" ]; then
  # Detect server type
  if grep -q "wrapServer" src/index.ts; then
    check_pass "wrapServer configuration found"
    
    # Check for auth provider
    if grep -q "authProvider" src/index.ts; then
      check_pass "authProvider configured"
    else
      check_fail "authProvider not configured"
    fi
    
    # Check for tokenResolver (dynamic servers)
    if grep -q "tokenResolver" src/index.ts; then
      check_pass "tokenResolver configured (dynamic server)"
      
      if [ -f "src/platform-token-resolver.ts" ]; then
        check_pass "src/platform-token-resolver.ts exists"
      else
        check_fail "src/platform-token-resolver.ts missing"
      fi
    else
      check_info "No tokenResolver (static server)"
    fi
    
  else
    check_warn "wrapServer not found in src/index.ts"
  fi
  
  # Check for auth provider files
  if [ -f "src/platform-jwt-provider.ts" ]; then
    check_pass "JWT provider file exists"
  fi
  
  if [ -f "src/platform-oauth-provider.ts" ]; then
    check_pass "OAuth provider file exists"
  fi
  
  if [ -f "src/platform-apikey-provider.ts" ]; then
    check_pass "API Key provider file exists"
  fi
fi

# Validate environment variables for auth
if [ -f ".env" ]; then
  set -a
  source .env 2>/dev/null || true
  set +a
  
  # JWT auth
  if grep -q "JWT" src/index.ts 2>/dev/null || grep -q "jwt" src/index.ts 2>/dev/null; then
    if [ -n "$JWT_SECRET" ]; then
      if [ ${#JWT_SECRET} -ge 32 ]; then
        check_pass "JWT_SECRET is set and strong (${#JWT_SECRET} chars)"
      else
        check_warn "JWT_SECRET is weak (${#JWT_SECRET} chars, recommend 32+)"
      fi
    else
      check_fail "JWT_SECRET not set"
    fi
    
    if [ -n "$JWT_ISSUER" ]; then
      check_pass "JWT_ISSUER is set"
    else
      check_warn "JWT_ISSUER not set"
    fi
    
    if [ -n "$JWT_AUDIENCE" ]; then
      check_pass "JWT_AUDIENCE is set"
    else
      check_warn "JWT_AUDIENCE not set"
    fi
  fi
  
  # OAuth auth
  if grep -q "OAuth" src/index.ts 2>/dev/null || grep -q "oauth" src/index.ts 2>/dev/null; then
    if [ -n "$OAUTH_CLIENT_ID" ]; then
      check_pass "OAUTH_CLIENT_ID is set"
    else
      check_fail "OAUTH_CLIENT_ID not set"
    fi
    
    if [ -n "$OAUTH_CLIENT_SECRET" ]; then
      check_pass "OAUTH_CLIENT_SECRET is set"
    else
      check_fail "OAUTH_CLIENT_SECRET not set"
    fi
  fi
  
  # Platform API (dynamic servers)
  if [ -f "src/platform-token-resolver.ts" ]; then
    if [ -n "$PLATFORM_API_URL" ]; then
      check_pass "PLATFORM_API_URL is set"
    else
      check_fail "PLATFORM_API_URL not set (required for dynamic server)"
    fi
  fi
fi

# ============================================================================
# Step 9: Validate Docker Configuration (Full)
# ============================================================================

if [ "$VALIDATION_LEVEL" = "full" ] && [ "$SKIP_DOCKER" = false ]; then
  print_section "🐳 Docker Configuration"
  
  # Check Docker installation
  if command -v docker >/dev/null 2>&1; then
    check_pass "Docker is installed"
    
    if docker info >/dev/null 2>&1; then
      check_pass "Docker daemon is running"
      
      # Validate Dockerfiles
      if [ -f "Dockerfile.development" ]; then
        if grep -q "FROM node:" Dockerfile.development; then
          check_pass "Dockerfile.development has valid FROM"
        else
          check_warn "Dockerfile.development may have invalid FROM"
        fi
        
        if grep -q "WORKDIR" Dockerfile.development; then
          check_pass "Dockerfile.development has WORKDIR"
        else
          check_warn "Dockerfile.development missing WORKDIR"
        fi
      fi
      
      if [ -f "Dockerfile.production" ]; then
        if grep -q "FROM node:" Dockerfile.production; then
          check_pass "Dockerfile.production has valid FROM"
        else
          check_warn "Dockerfile.production may have invalid FROM"
        fi
        
        if grep -q "USER node" Dockerfile.production; then
          check_pass "Dockerfile.production runs as non-root user"
        else
          check_warn "Dockerfile.production may run as root (security risk)"
        fi
        
        # Check for multi-stage build
        STAGE_COUNT=$(grep -c "^FROM" Dockerfile.production)
        if [ "$STAGE_COUNT" -ge 2 ]; then
          check_pass "Dockerfile.production uses multi-stage build"
        else
          check_warn "Dockerfile.production not using multi-stage build"
        fi
      fi
      
      # Validate .dockerignore
      if [ -f ".dockerignore" ]; then
        if grep -q "node_modules" .dockerignore; then
          check_pass ".dockerignore excludes node_modules"
        else
          check_warn ".dockerignore doesn't exclude node_modules"
        fi
        
        if grep -q "\.env" .dockerignore; then
          check_pass ".dockerignore excludes .env files"
        else
          check_fail ".dockerignore doesn't exclude .env (security risk!)"
        fi
      fi
      
    else
      check_warn "Docker daemon not running"
    fi
  else
    check_info "Docker not installed (skipping Docker validation)"
  fi
fi

# ============================================================================
# Step 10: Validate Cloud Build Configuration (Full)
# ============================================================================

if [ "$VALIDATION_LEVEL" = "full" ]; then
  print_section "☁️  Cloud Build Configuration"
  
  if [ -f "cloudbuild.yaml" ]; then
    # Validate YAML syntax
    if command -v python3 >/dev/null 2>&1; then
      if python3 -c "import yaml; yaml.safe_load(open('cloudbuild.yaml'))" 2>/dev/null; then
        check_pass "cloudbuild.yaml has valid YAML syntax"
      else
        check_fail "cloudbuild.yaml has invalid YAML syntax"
      fi
    else
      check_info "Python not available, skipping YAML syntax check"
    fi
    
    # Check for required fields
    if grep -q "^steps:" cloudbuild.yaml; then
      check_pass "cloudbuild.yaml has steps defined"
    else
      check_fail "cloudbuild.yaml missing steps"
    fi
    
    if grep -q "^images:" cloudbuild.yaml; then
      check_pass "cloudbuild.yaml has images defined"
    else
      check_warn "cloudbuild.yaml missing images"
    fi
    
    # Check for substitutions
    if grep -q "_GCP_PROJECT_ID" cloudbuild.yaml; then
      check_pass "cloudbuild.yaml uses _GCP_PROJECT_ID substitution"
    else
      check_warn "cloudbuild.yaml may have hardcoded project ID"
    fi
    
    # Check for secrets
    if grep -q "availableSecrets" cloudbuild.yaml; then
      check_pass "cloudbuild.yaml configures secrets"
    else
      check_info "cloudbuild.yaml doesn't use secrets"
    fi
    
    # Check for required steps
    if grep -q "npm ci\|npm install" cloudbuild.yaml; then
      check_pass "cloudbuild.yaml installs dependencies"
    else
      check_warn "cloudbuild.yaml may not install dependencies"
    fi
    
    if grep -q "npm test" cloudbuild.yaml; then
      check_pass "cloudbuild.yaml runs tests"
    else
      check_warn "cloudbuild.yaml doesn't run tests"
    fi
    
    if grep -q "npm run build" cloudbuild.yaml; then
      check_pass "cloudbuild.yaml builds application"
    else
      check_warn "cloudbuild.yaml may not build application"
    fi
    
  else
    check_info "cloudbuild.yaml not found (deployment not configured)"
  fi
fi

# ============================================================================
# Generate Validation Report
# ============================================================================

print_header "📊 Validation Summary"

echo -e "${BOLD}Validation Level:${NC} $VALIDATION_LEVEL"
echo -e "${BOLD}Total Checks:${NC} $TOTAL_CHECKS"
echo -e "${GREEN}${BOLD}Passed:${NC} $PASSED_CHECKS"
echo -e "${RED}${BOLD}Failed:${NC} $FAILED_CHECKS"
echo -e "${YELLOW}${BOLD}Warnings:${NC} $WARNING_CHECKS"

# Calculate percentage
if [ $TOTAL_CHECKS -gt 0 ]; then
  PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
  echo -e "${BOLD}Success Rate:${NC} ${PERCENTAGE}%"
fi

# Show errors
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo -e "\n${RED}${BOLD}❌ Critical Issues:${NC}"
  for error in "${ERRORS[@]}"; do
    echo -e "  ${RED}•${NC} $error"
  done
fi

# Show warnings
if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo -e "\n${YELLOW}${BOLD}⚠️  Warnings:${NC}"
  for warning in "${WARNINGS[@]}"; do
    echo -e "  ${YELLOW}•${NC} $warning"
  done
fi

# Show info
if [ "$VERBOSE" = true ] && [ ${#INFO[@]} -gt 0 ]; then
  echo -e "\n${BLUE}${BOLD}ℹ️  Information:${NC}"
  for info in "${INFO[@]}"; do
    echo -e "  ${BLUE}•${NC} $info"
  done
fi

# ============================================================================
# Remediation Suggestions
# ============================================================================

if [ $FAILED_CHECKS -gt 0 ] || [ $WARNING_CHECKS -gt 0 ]; then
  print_header "🔧 Remediation Steps"
  
  if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}${BOLD}Critical issues must be fixed:${NC}\n"
    
    # Missing dependencies
    if ! [ -d "node_modules" ]; then
      echo -e "${BOLD}1. Install dependencies:${NC}"
      echo -e "   npm install\n"
    fi
    
    # Missing files
    if ! [ -f "package.json" ] || ! [ -f "tsconfig.json" ] || ! [ -f "src/index.ts" ]; then
      echo -e "${BOLD}2. Reinitialize project:${NC}"
      echo -e "   @mcp-auth-server-base.init\n"
    fi
    
    # TypeScript errors
    if ! npx tsc --noEmit >/dev/null 2>&1; then
      echo -e "${BOLD}3. Fix TypeScript errors:${NC}"
      echo -e "   npx tsc --noEmit\n"
    fi
    
    # .env not in .gitignore
    if [ -f ".env" ] && ! grep -q "^\.env$" .gitignore 2>/dev/null; then
      echo -e "${BOLD}4. Add .env to .gitignore:${NC}"
      echo -e "   echo '.env' >> .gitignore\n"
    fi
  fi
  
  if [ $WARNING_CHECKS -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}Warnings should be addressed:${NC}\n"
    
    # Placeholder values
    if [ -f ".env" ] && grep -qi "your-.*-here\|placeholder\|changeme" .env 2>/dev/null; then
      echo -e "${BOLD}1. Replace placeholder values in .env:${NC}"
      echo -e "   # Generate strong JWT secret:"
      echo -e "   node -e \"console.log(require('crypto').randomBytes(32).toString('hex'))\"\n"
    fi
    
    # Missing .env
    if ! [ -f ".env" ] && [ -f ".env.example" ]; then
      echo -e "${BOLD}2. Create .env from example:${NC}"
      echo -e "   cp .env.example .env\n"
    fi
  fi
fi

# ============================================================================
# Next Steps
# ============================================================================

print_header "🎯 Next Steps"

if [ $FAILED_CHECKS -eq 0 ]; then
  echo -e "${GREEN}✅ Project validation passed!${NC}\n"
  
  if [ $WARNING_CHECKS -eq 0 ]; then
    echo "Your project is fully validated and ready for:"
    echo "  • Development: npm run dev"
    echo "  • Deployment: @mcp-auth-server-base.deploy"
    echo "  • Testing: npm test"
  else
    echo "Your project passed validation with warnings."
    echo "Address warnings before deploying to production."
    echo ""
    echo "Next steps:"
    echo "  • Fix warnings listed above"
    echo "  • Run validation again: @mcp-auth-server-base.validate"
    echo "  • Deploy when ready: @mcp-auth-server-base.deploy"
  fi
else
  echo -e "${RED}❌ Project validation failed!${NC}\n"
  echo "Critical issues must be fixed before deployment."
  echo ""
  echo "Next steps:"
  echo "  • Review errors listed above"
  echo "  • Follow remediation steps"
  echo "  • Run validation again: @mcp-auth-server-base.validate"
fi

echo ""

# ============================================================================
# Exit Code
# ============================================================================

# Exit with error if critical failures
if [ $FAILED_CHECKS -gt 0 ]; then
  exit 1
fi

# Exit with warning code if warnings
if [ $WARNING_CHECKS -gt 0 ]; then
  exit 2
fi

# Success
exit 0