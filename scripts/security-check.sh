#!/bin/bash

# Security Check Script for CVE-2023-45853
# This script verifies that the zlib vulnerability has been fixed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="${1:-devops-app}"
IMAGE_TAG="${2:-latest}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${BLUE}🔒 Security Check for CVE-2023-45853${NC}"
echo -e "${BLUE}Image: ${FULL_IMAGE_NAME}${NC}"
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS: ${message}${NC}"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ FAIL: ${message}${NC}"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  WARN: ${message}${NC}"
    else
        echo -e "${BLUE}ℹ️  INFO: ${message}${NC}"
    fi
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_status "FAIL" "Docker is not installed or not in PATH"
    exit 1
fi

# Check if image exists
if ! docker image inspect "$FULL_IMAGE_NAME" &> /dev/null; then
    print_status "FAIL" "Image $FULL_IMAGE_NAME does not exist"
    echo -e "${YELLOW}Please build the image first:${NC}"
    echo "  docker build -t $FULL_IMAGE_NAME ."
    exit 1
fi

print_status "PASS" "Image $FULL_IMAGE_NAME exists"

# Check zlib version in the image
echo -e "\n${BLUE}🔍 Checking zlib version...${NC}"

# Try to get zlib version from the image
ZLIB_VERSION=$(docker run --rm "$FULL_IMAGE_NAME" /bin/bash -c "
    # Try multiple methods to get zlib version
    if [ -f /usr/local/lib/libz.so.1.3.1 ]; then
        echo '1.3.1 (compiled from source)'
    elif [ -f /usr/local/lib/libz.so ]; then
        strings /usr/local/lib/libz.so | grep -E '^1\.[0-9]+\.[0-9]+' | head -1 || echo 'unknown'
    elif command -v dpkg &> /dev/null; then
        dpkg -l | grep zlib1g | awk '{print \$3}' | head -1 || echo 'not found'
    else
        echo 'unable to determine'
    fi
" 2>/dev/null || echo "error")

if [[ "$ZLIB_VERSION" == *"1.3.1"* ]]; then
    print_status "PASS" "zlib version: $ZLIB_VERSION (CVE-2023-45853 fixed)"
elif [[ "$ZLIB_VERSION" == *"1.3"* ]] && [[ "$ZLIB_VERSION" != *"1.3.1"* ]]; then
    print_status "FAIL" "zlib version: $ZLIB_VERSION (vulnerable to CVE-2023-45853)"
else
    print_status "WARN" "zlib version: $ZLIB_VERSION (unable to verify fix)"
fi

# Run Trivy scan if available
echo -e "\n${BLUE}🔍 Running vulnerability scan...${NC}"

if command -v trivy &> /dev/null; then
    print_status "INFO" "Running Trivy scan..."
    
    # Run Trivy scan and capture output
    TRIVY_OUTPUT=$(trivy image --quiet --format table "$FULL_IMAGE_NAME" 2>/dev/null || echo "scan_failed")
    
    if [[ "$TRIVY_OUTPUT" == "scan_failed" ]]; then
        print_status "WARN" "Trivy scan failed"
    elif echo "$TRIVY_OUTPUT" | grep -q "CVE-2023-45853"; then
        print_status "FAIL" "CVE-2023-45853 still detected by Trivy"
        echo -e "${YELLOW}Trivy output:${NC}"
        echo "$TRIVY_OUTPUT" | grep -A 2 -B 2 "CVE-2023-45853" || true
    else
        print_status "PASS" "CVE-2023-45853 not detected by Trivy"
    fi
    
    # Check for any critical vulnerabilities
    CRITICAL_COUNT=$(echo "$TRIVY_OUTPUT" | grep -c "CRITICAL" || echo "0")
    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        print_status "WARN" "$CRITICAL_COUNT critical vulnerabilities found"
    else
        print_status "PASS" "No critical vulnerabilities found"
    fi
else
    print_status "WARN" "Trivy not installed - skipping vulnerability scan"
    echo -e "${YELLOW}Install Trivy for comprehensive vulnerability scanning:${NC}"
    echo "  https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
fi

# Test application functionality
echo -e "\n${BLUE}🧪 Testing application functionality...${NC}"

# Start container in background
CONTAINER_ID=$(docker run -d -p 8080:8080 "$FULL_IMAGE_NAME" 2>/dev/null || echo "failed")

if [ "$CONTAINER_ID" = "failed" ]; then
    print_status "FAIL" "Failed to start container"
else
    print_status "PASS" "Container started successfully"
    
    # Wait for application to start
    sleep 5
    
    # Test health endpoint
    if curl -f -s http://localhost:8080/healthz > /dev/null 2>&1; then
        print_status "PASS" "Health check endpoint responding"
    else
        print_status "WARN" "Health check endpoint not responding (may need more time)"
    fi
    
    # Clean up
    docker stop "$CONTAINER_ID" > /dev/null 2>&1
    docker rm "$CONTAINER_ID" > /dev/null 2>&1
    print_status "INFO" "Container cleaned up"
fi

# Summary
echo -e "\n${BLUE}📋 Security Check Summary${NC}"
echo "=================================="
echo "Image: $FULL_IMAGE_NAME"
echo "zlib Version: $ZLIB_VERSION"
echo "CVE-2023-45853 Status: $(if [[ "$ZLIB_VERSION" == *"1.3.1"* ]]; then echo "FIXED"; else echo "NEEDS ATTENTION"; fi)"

# Exit with appropriate code
if [[ "$ZLIB_VERSION" == *"1.3.1"* ]]; then
    echo -e "\n${GREEN}🎉 Security check completed successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  Security issues detected. Please review and fix.${NC}"
    exit 1
fi 