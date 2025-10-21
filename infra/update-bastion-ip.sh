#!/bin/bash

# -----------------------------------------------
# update-bastion-ip.sh
# Dynamically updates your Terraform tfvars file
# with your current public IP for SSH ingress.
# -----------------------------------------------

# Exit on error
set -e

# File to update
TFVARS_FILE="terraform-ap-south-1.tfvars"

# Get current public IP
echo "Fetching current public IP..."
CURRENT_IP=$(curl -s https://checkip.amazonaws.com)

# Validate IP format
if [[ ! $CURRENT_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Failed to detect valid public IP. Got: $CURRENT_IP"
  exit 1
fi

# Format as CIDR
CIDR="${CURRENT_IP}/32"

echo "✅ Current IP detected: $CIDR"
echo "Updating $TFVARS_FILE ..."

# Replace existing cidr_blocks_ingress_bastion line
# This works whether or not whitespace or quotes differ
sed -i.bak -E "s|^cidr_blocks_ingress_bastion *= *\[\"[0-9./]+\"\]|cidr_blocks_ingress_bastion = [\"${CIDR}\"]|" "$TFVARS_FILE"

# If the line does not exist (edge case), append it
if ! grep -q "cidr_blocks_ingress_bastion" "$TFVARS_FILE"; then
  echo "" >> "$TFVARS_FILE"
  echo "cidr_blocks_ingress_bastion = [\"${CIDR}\"]" >> "$TFVARS_FILE"
fi

echo "✅ $TFVARS_FILE updated successfully!"
echo "-----------------------------------------"
grep "cidr_blocks_ingress_bastion" "$TFVARS_FILE"
echo "-----------------------------------------"

# Optional: auto-run Terraform
read -p "Do you want to run 'terraform apply' now? [y/N]: " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  echo "Running terraform init and apply..."
  terraform init -backend-config="backend-ap-south-1.hcl"
  terraform apply -var-file="$TFVARS_FILE" -auto-approve
else
  echo "Skipped Terraform apply. You can run it manually later."
fi
