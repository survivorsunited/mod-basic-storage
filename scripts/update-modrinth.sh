#!/bin/bash

# Update Modrinth Project Description
# Updates the project description on Modrinth using the API

set -e

# Default values
DESCRIPTION_FILE="docs/MODRINTH.md"
SHOW_HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--token)
      MODRINTH_TOKEN="$2"
      shift 2
      ;;
    -p|--project-id)
      PROJECT_ID="$2"
      shift 2
      ;;
    -f|--file)
      DESCRIPTION_FILE="$2"
      shift 2
      ;;
    -h|--help)
      SHOW_HELP=true
      shift
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Show help
if [ "$SHOW_HELP" = true ]; then
  cat << EOF
Update Modrinth Project Description

Usage: ./scripts/update-modrinth.sh [options]

Options:
  -t, --token <token>       Modrinth API token (or set MODRINTH_TOKEN env var)
  -p, --project-id <id>     Project ID/slug (or set PROJECT_ID env var)  
  -f, --file <path>         Path to description file (default: docs/MODRINTH.md)
  -h, --help               Show this help message

Environment Variables:
  MODRINTH_TOKEN   Your Modrinth API token
  PROJECT_ID       Your project ID/slug (e.g., su-compostables)

Example:
  ./scripts/update-modrinth.sh --token "your-token" --project-id "su-compostables"
EOF
  exit 0
fi

# Check for required tools
if ! command -v curl &> /dev/null; then
  echo "❌ curl is required but not found!"
  echo "Please install curl"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "❌ jq is required but not found!"
  echo "Please install jq for JSON processing"
  exit 1
fi

# Validate parameters
if [ -z "$MODRINTH_TOKEN" ]; then
  echo "❌ Modrinth token is required!"
  echo "Set the MODRINTH_TOKEN environment variable or use --token parameter"
  echo "Get your token from: https://modrinth.com/settings/account"
  exit 1
fi

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Project ID is required!"
  echo "Set the PROJECT_ID environment variable or use --project-id parameter"
  echo "Find your project ID in the Modrinth project URL"
  exit 1
fi

# Check if description file exists
if [ ! -f "$DESCRIPTION_FILE" ]; then
  # Try fallback to docs version
  FALLBACK_FILE="docs/docs/modrinth.md"
  if [ -f "$FALLBACK_FILE" ]; then
    echo "⚠️  $DESCRIPTION_FILE not found, using $FALLBACK_FILE"
    DESCRIPTION_FILE="$FALLBACK_FILE"
  else
    echo "❌ Description file not found: $DESCRIPTION_FILE"
    echo "Please ensure the description file exists"
    exit 1
  fi
fi

echo "🚀 Updating Modrinth project description..."
echo "Project ID: $PROJECT_ID"
echo "Description file: $DESCRIPTION_FILE"

# Prepare description content
if [[ "$DESCRIPTION_FILE" == *"docs/modrinth.md" ]]; then
  # Extract content after front matter for docs version
  DESCRIPTION=$(awk '/^---$/{if(++count==2)next}/^---$/&&count<2{next}1' "$DESCRIPTION_FILE")
else
  # Use file as-is for standalone MODRINTH.md
  DESCRIPTION=$(cat "$DESCRIPTION_FILE")
fi

# Create JSON payload
JSON_PAYLOAD=$(jq -n --arg desc "$DESCRIPTION" '{description: $desc}')

echo "📡 Sending API request..."

# Make API request
RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X PATCH \
  -H "Authorization: Bearer $MODRINTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "https://api.modrinth.com/v3/project/$PROJECT_ID")

# Extract HTTP status and body
HTTP_STATUS=$(echo "$RESPONSE" | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')
BODY=$(echo "$RESPONSE" | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ Modrinth project description updated successfully!"
  
  # Try to display response info
  if command -v jq &> /dev/null && echo "$BODY" | jq . > /dev/null 2>&1; then
    TITLE=$(echo "$BODY" | jq -r '.title // empty')
    DESC_LENGTH=$(echo "$BODY" | jq -r '.description | length')
    
    if [ -n "$TITLE" ]; then
      echo "Project: $TITLE"
    fi
    if [ -n "$DESC_LENGTH" ]; then
      echo "Description length: $DESC_LENGTH characters"
    fi
  fi
  
  echo "🌐 View your project: https://modrinth.com/mod/$PROJECT_ID"
else
  echo "❌ Failed to update Modrinth project description (HTTP $HTTP_STATUS)"
  echo "Error response: $BODY"
  
  # Common error messages
  if [ "$HTTP_STATUS" -eq 401 ]; then
    echo ""
    echo "💡 Common fixes for 401 Unauthorized:"
    echo "- Check that your API token is valid"
    echo "- Ensure you have permission to edit this project"
    echo "- Verify the token hasn't expired"
  elif [ "$HTTP_STATUS" -eq 404 ]; then
    echo ""
    echo "💡 Common fixes for 404 Not Found:"
    echo "- Check that the project ID '$PROJECT_ID' is correct"
    echo "- Verify the project exists and is published"
  fi
  
  exit 1
fi