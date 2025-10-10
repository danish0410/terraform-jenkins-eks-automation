#!/bin/bash
# =====================================================================
# Script: generate_ed25519_key.sh
# Purpose: Generate a secure ED25519 SSH key pair and upload to AWS EC2
# Usage:
#   ./scripts/generate_ed25519_key.sh <key_name> [region]
# Example:
#   ./scripts/generate_ed25519_key.sh dev-servme-ap-southeast-1 ap-southeast-1
# =====================================================================

set -e

# --- Input Parameters ---
KEY_NAME="$1"
AWS_REGION="$2"

if [ -z "$KEY_NAME" ]; then
  echo "❌ Error: Key name not provided."
  echo "Usage: $0 <key_name> [region]"
  exit 1
fi

# --- Detect or Validate AWS Region ---
if [ -z "$AWS_REGION" ]; then
  AWS_REGION=$(aws configure get region 2>/dev/null || true)
fi
if [ -z "$AWS_REGION" ]; then
  echo "❌ AWS region not set. Please pass it as an argument or configure AWS CLI."
  echo "Example: ./generate_ed25519_key.sh dev-servme-ap-southeast-1 ap-southeast-1"
  exit 1
fi

# --- Prerequisite Checks ---
if ! command -v aws &>/dev/null; then
  echo "❌ AWS CLI not installed. Please install it first (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)."
  exit 1
fi
if ! command -v ssh-keygen &>/dev/null; then
  echo "❌ ssh-keygen command not found. Please install OpenSSH utilities."
  exit 1
fi

# --- Paths ---
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRIVATE_KEY_PATH="${PROJECT_DIR}/${KEY_NAME}"
PUBLIC_KEY_PATH="${PROJECT_DIR}/${KEY_NAME}.pub"

# --- Handle Existing Keys ---
if [ -f "$PRIVATE_KEY_PATH" ]; then
  echo "⚠️  Key already exists: $PRIVATE_KEY_PATH"
  read -p "Do you want to overwrite it? (y/N): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "✅ Keeping existing key. Exiting."
    exit 0
  fi
  rm -f "$PRIVATE_KEY_PATH" "$PUBLIC_KEY_PATH"
fi

# --- Generate New ED25519 Key Pair ---
echo "🔐 Generating ED25519 SSH key pair..."
ssh-keygen -t ed25519 -f "$PRIVATE_KEY_PATH" -N "" -C "$KEY_NAME" >/dev/null

chmod 400 "$PRIVATE_KEY_PATH"
chmod 644 "$PUBLIC_KEY_PATH"

echo ""
echo "✅ Key pair generated successfully:"
echo "Private key: $PRIVATE_KEY_PATH"
echo "Public key:  $PUBLIC_KEY_PATH"
echo ""

# --- Upload Public Key to AWS ---
echo "☁️  Uploading public key to AWS EC2 as Key Pair..."

# Check if AWS key already exists
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

# Import public key into AWS
aws ec2 import-key-pair \
  --key-name "$KEY_NAME" \
  --public-key-material "fileb://${PUBLIC_KEY_PATH}" \
  --region "$AWS_REGION" >/dev/null

echo ""
echo "✅ AWS Key Pair imported successfully!"
echo "🔹 AWS Key Name: $KEY_NAME"
echo "🔹 Region:       $AWS_REGION"
echo ""
echo "👉 Terraform can reference this key as:"
echo "   key_name = \"$KEY_NAME\""
echo "   region   = \"$AWS_REGION\""
echo ""
echo "Done ✅"