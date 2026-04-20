#!/bin/bash
# Đọc .env từ project root và tạo Env.xcconfig cho Xcode
ENV_FILE="${SRCROOT}/../../.env"
OUTPUT_FILE="${SRCROOT}/Flutter/Env.xcconfig"

if [ -f "$ENV_FILE" ]; then
  # Chỉ lấy GOOGLE_MAPS_API_KEY
  GOOGLE_MAPS_API_KEY=$(grep '^GOOGLE_MAPS_API_KEY=' "$ENV_FILE" | cut -d '=' -f2-)
  echo "GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}" > "$OUTPUT_FILE"
  echo "Generated Env.xcconfig with GOOGLE_MAPS_API_KEY"
else
  echo "// .env not found" > "$OUTPUT_FILE"
  echo "WARNING: .env file not found at $ENV_FILE"
fi
