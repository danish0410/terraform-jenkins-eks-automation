#!/bin/bash
# =====================================================================
# Script: generate_ed25519_key.sh
# Purpose: Generate a secure ED25519 SSH key pair and upload to AWS
# Usage: ./generate_ed25519_key.sh <key_name> [region]
# Example: ./generate_ed25519_key.sh bastion-ap-south-1 ap-south-1
# =====================================================================

set -e

# --- Input Validation ---
KEY_NAME="$1"
AWS_REGION="$2"

if [ -z "$KEY_NAME" ]; then
  echo "❌ Error: Key name not provided."
  echo "Usage: $0 <key_name> [region]"
  exit 1
fi

# --- Detect AWS Region ---
if [ -z "$AWS_REGION" ]; then
  AWS_REGION=$(aws configure get region 2>/dev/null || true)
fi
if [ -z "$AWS_REGION" ]; then
  echo "❌ AWS region not set. Please pass it as an argument or configure AWS CLI."
  echo "Example: ./generate_ed25519_key.sh bastion-ap-south-1 ap-south-1"
  exit 1
fi

# --- Check AWS CLI ---
if ! command -v aws &>/dev/null; then
  echo "❌ AWS CLI not installed. Please install it first."
  exit 1
fi

# --- Key Paths ---
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRIVATE_KEY_PATH="${PROJECT_DIR}/${KEY_NAME}.pem"
PUBLIC_KEY_PATH="${PROJECT_DIR}/${KEY_NAME}.pub"

# --- Check Existing Key ---
if [ -f "$PRIVATE_KEY_PATH" ]; then
  echo "⚠️  Key already exists: $PRIVATE_KEY_PATH"
  read -p "Do you want to overwrite it? (y/N): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "✅ Keeping existing key. Exiting."
    exit 0
  fi
fi

# --- Generate ED25519 Key Pair ---
echo "🔐 Generating ED25519 SSH key pair..."
ssh-keygen -t ed25519 -f "$PRIVATE_KEY_PATH" -N "" -C "$KEY_NAME" >/dev/null

chmod 400 "$PRIVATE_KEY_PATH"
chmod 644 "$PUBLIC_KEY_PATH"

echo "✅ Key pair generated:"
echo "Private key: $PRIVATE_KEY_PATH"
echo "Public key:  $PUBLIC_KEY_PATH"
echo ""

# --- Upload Public Key to AWS ---
echo "☁️  Uploading public key to AWS as EC2 Key Pair..."

# Check if key already exists in AWS
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "⚠️  AWS Key Pair '$KEY_NAME' already exists in region '$AWS_REGION'."
  read -p "Do you want to delete and recreate it? (y/N): " CONFIRM_AWS
  if [[ "$CONFIRM_AWS" =~ ^[Yy]$ ]]; then
    aws ec2 delete-key-pair --key-name "$KEY_NAME" --region "$AWS_REGION"
    echo "🗑️  Deleted existing AWS key pair."
  else
    echo "✅ Keeping existing AWS key pair. Exiting."
    exit 0
  fi
fi

# Create new AWS Key Pair
aws ec2 import-key-pair \
  --key-name "$KEY_NAME" \
  --public-key-material "fileb://${PUBLIC_KEY_PATH}" \
  --region "$AWS_REGION" >/dev/null

echo "✅ AWS Key Pair uploaded successfully!"
echo ""
echo "🔹 AWS Key Name: $KEY_NAME"
echo "🔹 Region:       $AWS_REGION"
echo ""
echo "👉 Use this in your Terraform variables:"
echo "   key_name = \"$KEY_NAME\""
echo "   region   = \"$AWS_REGION\""
echo ""
echo "Done ✅"