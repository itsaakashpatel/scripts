#!/bin/bash
# A script to bundle and upload a node.js application to Artifactory
# Configuration - Edit these variables
APP_NAME="file-watch"
APP_VERSION=$(date +"%Y%m%d%H%M%S")
ARTIFACTORY_URL="https://your-artifactory-url/artifactory"
ARTIFACTORY_REPO="npm-local"
ARTIFACTORY_USER="username"
ARTIFACTORY_PASSWORD="password"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting bundle and upload process for ${APP_NAME}-${APP_VERSION}${NC}"

# Check if required commands exist
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm command not found. Please install Node.js and npm.${NC}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}curl command not found. Please install curl.${NC}"
    exit 1
fi

# Create build directory
BUILD_DIR="dist"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo -e "${YELLOW}Installing dependencies...${NC}"
npm install || { echo -e "${RED}Failed to install dependencies${NC}"; exit 1; }

echo -e "${YELLOW}Running build script if it exists...${NC}"
npm run build --if-present

echo -e "${YELLOW}Creating package tarball...${NC}"
npm pack || { echo -e "${RED}Failed to create package${NC}"; exit 1; }

# Move the tarball to build directory
TARBALL="${APP_NAME}-${APP_VERSION}.tgz"
mv "${APP_NAME}-"*.tgz "$BUILD_DIR/$TARBALL"

if [ ! -f "$BUILD_DIR/$TARBALL" ]; then
    echo -e "${RED}Failed to find the generated tarball${NC}"
    exit 1
fi

echo -e "Successfully created tarball at ${BUILD_DIR}/${TARBALL}"

# Upload to Artifactory
echo -e "${YELLOW}Uploading package to Artifactory...${NC}"
UPLOAD_URL="${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}/${APP_NAME}/${APP_VERSION}/${TARBALL}"

curl -u "${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD}" \
     -X PUT "${UPLOAD_URL}" \
     -T "$BUILD_DIR/$TARBALL" \
     -H "Content-Type: application/gzip" \
     || { echo -e "${RED}Failed to upload to Artifactory${NC}"; exit 1; }

# Check if upload was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Package successfully uploaded to Artifactory!${NC}"
    echo -e "${GREEN}Download URL: ${UPLOAD_URL}${NC}"
    echo -e "${YELLOW}You can download this package using:${NC}"
    echo "wget --user=${ARTIFACTORY_USER} --password=YOUR_PASSWORD ${UPLOAD_URL}"
    echo -e "${YELLOW}Or without credentials if your Artifactory allows anonymous downloads:${NC}"
    echo "wget ${UPLOAD_URL}"
else
    echo -e "${RED}Package upload failed${NC}"
    exit 1
fi

echo -e "${YELLOW}Bundle & upload process complete${NC}"