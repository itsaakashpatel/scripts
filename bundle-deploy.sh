#!/bin/bash

# A script to deploy a node.js application to a server and start it with PM2

# Set variables
APP_NAME="my-node-app"
APP_VERSION="1.0.0"
TARBALL="${APP_NAME}-${APP_VERSION}.tgz"

# Cleanup and prepare
rm -rf package
mkdir -p /opt/${APP_NAME}

# Extract application
tar -xzf ${TARBALL}
mv package/* /opt/${APP_NAME}/

# Install dependencies
cd /opt/${APP_NAME}

#Install pm2 if not installed
if ! command -v pm2 &> /dev/null; then
  npm install -g pm2
fi
 
# Start with PM2
pm2 delete ${APP_NAME} 2>/dev/null || true
pm2 start index.js --name ${APP_NAME}
pm2 save