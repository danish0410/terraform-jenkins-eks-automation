#!/usr/bin/env bash
# ==========================================================
# generate_ed25519_key.sh
# Safe ED25519 key generator & AWS importer for Terraform use
# ==========================================================

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <key_name> <region>"
  echo "Example: $0 dev-classic-ap-south-1 ap-south-1"
  exit 2
fi

KEY_NAME="$1"    # Example: dev-classic-ap-south-1
REGION="$2"      # Example: ap-south-1
SSH_DIR="${HOME}/.ssh"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

PRIVATE_KEY="${SSH_DIR}/${KEY_NAME}"
PUBLIC_KEY="${PRIVATE_KEY}.pub"
PEM_KEY="${PRIVATE_KEY}.pem"

echo "🧹 Cleaning old key files..."
rm -f "${PRIVATE_KEY}" "${PUBLIC_KEY}" "${PEM_KEY}"

echo "🔐 Generating new ED25519 key pair..."
ssh-keygen -t ed25519 -f "$PRIVATE_KEY" -N "" -C "$KEY_NAME" >/dev/null
chmod 400 "$PRIVATE_KEY"

echo "☁️  Syncing AWS Key Pair..."
aws ec2 delete-key-pair --key-name "$KEY_NAME" --region "$REGION" >/dev/null 2>&1 || true
aws ec2 import-key-pair \
  --key-name "$KEY_NAME" \
  --public-key-material "fileb://${PUBLIC_KEY}" \
  --region "$REGION" >/dev/null

echo "📦 Creating .pem copy for Terraform use..."
cp "$PRIVATE_KEY" "$PEM_KEY"
chmod 400 "$PEM_KEY"

echo "✅ Key setup complete!"
echo "------------------------------------------------"
echo "Private Key (.pem): $PEM_KEY"
echo "Public Key (.pub):  $PUBLIC_KEY"
echo "AWS KeyPair:        $KEY_NAME"
echo "Region:             $REGION"
echo "------------------------------------------------"