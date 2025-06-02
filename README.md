# SCP Deny Checker

A utility script to search for AWS Service Control Policies (SCPs) that explicitly deny specific IAM actions.

## Overview

This script helps AWS administrators identify which Service Control Policies are denying specific actions across an AWS Organization. It searches through all SCPs in an AWS Organization and identifies policies that explicitly deny the specified IAM action, including both exact matches and wildcard patterns.

## Prerequisites

- Python 3 (pre-installed on most Linux distributions)
- AWS CLI configured with access to the AWS Organizations service
- Appropriate permissions to list and describe SCPs

## Important: Access Requirements

**This script must be run with access to the AWS Organizations management account:**

1. **AWS CLI Option**: Run the script with an AWS profile that has access to the AWS Organizations management account
   ```bash
   ./scp-deny-checker.sh --profile management-account s3:GetObject
   ```

2. **AWS CloudShell Option**: Run the script directly in AWS CloudShell while logged into the AWS Organizations management account console

Without access to the management account, the script will not be able to retrieve SCPs and will not function correctly.

## Installation

1. Download the script:
   ```bash
   git clone https://github.com/linkcd/scp-deny-checker.git
   cd scp-deny-checker
   ```

2. Make the script executable:
   ```bash
   chmod +x scp-deny-checker.sh
   ```

## Usage

```bash
./scp-deny-checker.sh [options] <iam-action>
```

### Options

- `-p, --profile PROFILE` - AWS CLI profile to use (default: 'default')
- `-h, --help` - Show help message

### Examples

```bash
# Check for policies denying S3 GetObject using default profile
./scp-deny-checker.sh s3:GetObject

# Check using a specific AWS profile
./scp-deny-checker.sh --profile org-admin ec2:DescribeInstances

# Check for policies denying Lambda function creation
./scp-deny-checker.sh -p management lambda:CreateFunction
```

## Output

The script will output:
- The name and ID of any SCP that denies the specified action
- The specific statement(s) within the policy that contain the deny
- A summary of the search results

## Troubleshooting

- Ensure you're running the script with access to the AWS Organizations management account
- Verify your AWS CLI credentials are correctly configured
- Check that you have the necessary permissions to list and describe SCPs

## Disclaimer

This script was generated with assistance from Amazon Q and should be treated as any code written by AI. While efforts have been made to ensure its accuracy and functionality, it should be reviewed and tested thoroughly before use in production environments. The user assumes all responsibility for the use of this script.

## License

This project is licensed under the MIT License - see the LICENSE file for details.