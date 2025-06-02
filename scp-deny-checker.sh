#!/bin/bash

# Default profile is 'default'
PROFILE="default"

# Function to display usage
function show_usage {
  echo "Usage: $0 [options] <iam-action>"
  echo "Options:"
  echo "  -p, --profile PROFILE    AWS CLI profile to use (default: 'default')"
  echo "  -h, --help               Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 polly:SynthesizeSpeech"
  echo "  $0 --profile prod ec2:DescribeImages"
  echo "  $0 -p dev s3:GetObject"
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--profile)
      PROFILE="$2"
      shift 2
      ;;
    -h|--help)
      show_usage
      ;;
    *)
      # If it's not an option, it must be the action
      ACTION="$1"
      shift
      break
      ;;
  esac
done

# Check if action parameter is provided
if [ -z "$ACTION" ]; then
  show_usage
fi

echo "Searching for SCPs that explicitly deny '$ACTION' using profile '$PROFILE'..."

# Get all SCPs with the specified profile
policies=$(aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[*].Id' --output text --profile "$PROFILE")

# For each policy
for policy_id in $policies; do
  # Get policy name for better identification
  policy_name=$(aws organizations describe-policy --policy-id $policy_id --query 'Policy.PolicySummary.Name' --output text --profile "$PROFILE")
  
  # Get policy content (the actual JSON document)
  policy_content=$(aws organizations describe-policy --policy-id $policy_id --query 'Policy.Content' --output text --profile "$PROFILE")
  
  # Use Python to process JSON instead of jq
  python_result=$(python3 -c "
import json
import sys
import re

# Extract service and action parts
action = '$ACTION'
service_part = action.split(':')[0] if ':' in action else ''
action_wildcard = service_part + ':*' if service_part else ''

try:
    # Parse the policy content
    policy = json.loads('''$policy_content''')
    
    # Check if Statement exists and is a list
    if 'Statement' not in policy:
        sys.exit(0)
    
    statements = policy['Statement']
    if not isinstance(statements, list):
        statements = [statements]
    
    # Find denying statements
    denying_statements = []
    for stmt in statements:
        if stmt.get('Effect') != 'Deny':
            continue
            
        actions = stmt.get('Action', [])
        if isinstance(actions, str):
            actions = [actions]
            
        # Check if action is denied
        if ('*' in actions or 
            action in actions or 
            (action_wildcard and action_wildcard in actions)):
            denying_statements.append(json.dumps(stmt, indent=2))
    
    # Print results
    if denying_statements:
        print('FOUND_DENY')
        for stmt in denying_statements:
            print(stmt)
    
except json.JSONDecodeError:
    print('INVALID_JSON')
except Exception as e:
    print(f'ERROR: {str(e)}')
" 2>/dev/null)

  # Process the Python output
  if [[ $python_result == INVALID_JSON* ]]; then
    echo "Warning: Policy $policy_id ($policy_name) contains invalid JSON. Skipping."
    continue
  elif [[ $python_result == ERROR* ]]; then
    echo "Error processing policy $policy_id ($policy_name): ${python_result#ERROR: }"
    continue
  elif [[ $python_result == FOUND_DENY* ]]; then
    echo "Found policy explicitly denying '$ACTION': $policy_name (ID: $policy_id)"
    echo "Denying statements:"
    echo "${python_result#FOUND_DENY}"
    echo "----------------------------------------------"
  fi
done

echo "Search complete."