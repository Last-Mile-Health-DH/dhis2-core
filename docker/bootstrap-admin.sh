#!/bin/sh
# Renames DHIS2's built-in default admin user (admin/district) to the credentials
# configured via ADMIN_USERNAME/ADMIN_PASSWORD/ADMIN_EMAIL.
set -eu

ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-district}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
BASE_URL="http://web:8080"
DEFAULT_USER_ID="M5zQapPyTZI" # uid DHIS2 assigns to the default admin user

echo "Waiting for DHIS2 API to become available..."
until curl -sf -o /dev/null "$BASE_URL/api/system/info"; do
  sleep 5
done

if curl -sf -u "$ADMIN_USERNAME:$ADMIN_PASSWORD" -o /dev/null "$BASE_URL/api/me"; then
  echo "Admin credentials already match the configured values, nothing to do."
  exit 0
fi

echo "Applying custom admin credentials to the default admin user..."
USER_JSON=$(curl -sf -u admin:district "$BASE_URL/api/users/${DEFAULT_USER_ID}.json")

UPDATED_JSON=$(echo "$USER_JSON" | jq \
  --arg username "$ADMIN_USERNAME" \
  --arg password "$ADMIN_PASSWORD" \
  --arg email "$ADMIN_EMAIL" \
  '.username = $username | .email = $email | .password = $password')

HTTP_STATUS=$(curl -s -o /tmp/response.json -w '%{http_code}' -u admin:district -X PUT \
  -H "Content-Type: application/json" -d "$UPDATED_JSON" "$BASE_URL/api/users/${DEFAULT_USER_ID}")

if [ "$HTTP_STATUS" -ge 400 ]; then
  echo "Failed to update admin user (HTTP $HTTP_STATUS):"
  cat /tmp/response.json
  exit 1
fi

echo "Admin credentials updated."
