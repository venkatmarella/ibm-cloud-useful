#!/bin/bash

##########################  
# Author: Venkat Marella
# Date: 2024-10-06
# Version: v0.0.1

# Purpose: This script to bring all ibm cloud resources in classic and vpc in your ibm account
###########################


#!/bin/bash

# Function to install IBM Cloud CLI
install_ibmcloud_cli() {
    echo "Installing IBM Cloud CLI..."
    curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
}

# Function to check and install IBM Cloud CLI plugins
install_ibmcloud_plugins() {
    echo "Checking and installing IBM Cloud CLI plugins..."

    # Check and install infrastructure-service plugin
    if ! ibmcloud plugin list | grep -q "infrastructure-service"; then
        echo "Installing infrastructure-service plugin..."
        ibmcloud plugin install infrastructure-service -f
    else
        echo "infrastructure-service plugin is already installed."
    fi

    # Check and install vpc-infrastructure plugin
    if ! ibmcloud plugin list | grep -q "vpc-infrastructure"; then
        echo "Installing vpc-infrastructure plugin..."
        ibmcloud plugin install vpc-infrastructure -f
    else
        echo "vpc-infrastructure plugin is already installed."
    fi
}

# Ensure IBM Cloud CLI is installed
if ! command -v ibmcloud &> /dev/null; then
    echo "IBM Cloud CLI is not installed. Installing now..."
    install_ibmcloud_cli
fi

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it first."
    exit 1
fi

# Install necessary plugins
install_ibmcloud_plugins

# Log in to IBM Cloud if not already logged in
if ! ibmcloud target &> /dev/null; then
    echo "Logging into IBM Cloud..."
    ibmcloud login --sso
fi

# Get the list of available resource groups
AVAILABLE_GROUPS=$(ibmcloud resource groups --output JSON | jq -r '.[].name')

# Prompt the user for resource group
read -p "Enter the resource group: " RESOURCE_GROUP

# Check if the entered resource group is valid
if ! echo "$AVAILABLE_GROUPS" | grep -q "^$RESOURCE_GROUP$"; then
    echo "Invalid resource group. Defaulting to 'Default'."
    RESOURCE_GROUP="Default"
fi

# Target the resource group
echo "Targeting resource group: $RESOURCE_GROUP"
ibmcloud target -g "$RESOURCE_GROUP"

# Provide a list of available regions
echo "Select a region from the list below:"
REGIONS=("us-south" "us-east" "eu-gb" "eu-de" "au-syd" "jp-tok")
select REGION in "${REGIONS[@]}"; do
    if [[ -n "$REGION" ]]; then
        echo "You have selected region: $REGION"
        break
    else
        echo "Invalid selection. Please choose a valid region."
    fi
done

# Target the selected region
ibmcloud target -r "$REGION"

# Loop to continuously prompt the user
while true; do
    # Prompt the user for the type of resources to list
    echo "Select the type of resources to list:"
    echo "1) Classic Infrastructure"
    echo "2) VPC"
    echo "3) Exit"
    read -p "Enter your choice (1, 2, or 3): " CHOICE

    # Use a case statement to handle the user's choice
    case $CHOICE in
        1)
            echo "Listing Classic Infrastructure resources..."
            echo "Classic Devices:"
            ibmcloud sl hardware list || echo "Failed to list Classic Devices."

            echo "Classic Virtual Servers:"
            ibmcloud sl vs list || echo "Failed to list Classic Virtual Servers."

            echo "Classic Networks:"
            ibmcloud sl vlan list || echo "Failed to list Classic Networks."
            ;;
        2)
            echo "Listing VPC resources..."
            echo "VPCs:"
            ibmcloud is vpcs || echo "Failed to list VPCs."

            echo "Subnets:"
            ibmcloud is subnets || echo "Failed to list Subnets."

            echo "Virtual Servers:"
            ibmcloud is instances || echo "Failed to list Virtual Servers."

            echo "Public Gateways:"
            ibmcloud is public-gateways || echo "Failed to list Public Gateways."

            echo "Security Groups:"
            ibmcloud is security-groups || echo "Failed to list Security Groups."
            ;;
        3)
            echo "Exiting the script. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
    esac
done
