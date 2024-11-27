#!/bin/bash

# Securely load OpenStack credentials
# Replace placeholders or use an external .env file for sensitive values

# Prompt user for sensitive information (uncomment if needed)
# read -p "Enter OS_USERNAME: " OS_USERNAME
# read -p "Enter OS_PROJECT_NAME: " OS_PROJECT_NAME
# read -s -p "Enter OS_PASSWORD: " OS_PASSWORD; echo
# read -p "Enter OS_AUTH_URL: " OS_AUTH_URL

# Alternatively, load credentials from a secure file (e.g., .env)
if [ -f .env ]; then
    echo "Loading credentials from .env file..."
    source .env
else
    echo "Error: .env file not found! Please provide your credentials."
    exit 1
fi

# Export OpenStack variables
export OS_USERNAME=$OS_USERNAME
export OS_PROJECT_NAME=$OS_PROJECT_NAME
export OS_PASSWORD=$OS_PASSWORD
export OS_USER_DOMAIN_NAME=${OS_USER_DOMAIN_NAME:-Default}
export OS_PROJECT_DOMAIN_NAME=${OS_PROJECT_DOMAIN_NAME:-Default}
export OS_AUTH_URL=$OS_AUTH_URL
export OS_IDENTITY_API_VERSION=3

# Verify credentials are loaded
echo "OpenStack credentials loaded successfully!"
