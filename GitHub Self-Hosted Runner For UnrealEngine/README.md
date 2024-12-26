# GitHub Self-Hosted Runner Setup for Unreal Engine Projects on AWS

This folder provides Infrastructure as Code (IaC) configurations to set up a self-hosted GitHub Actions runner optimized for Unreal Engine projects, with cost-effectiveness in mind.

## Overview

This setup leverages AWS services to create and manage a GitHub self-hosted runner for Unreal Engine builds. It ensures scalability and efficient resource utilization.

## Prerequisites

1. **AWS Secrets Manager**:
   - Store the required tokens in AWS Secrets Manager with the following details:
     - **Personal Access Token (PAT)**:
       - Secret name: `github/runner_token`
       - Key: `Token`
     - **Webhook Token**:
       - Secret name: `github/webhook_token`
       - Key: `Token`

2. **AWS CLI**:
   Ensure the AWS CLI is configured with the appropriate permissions to access AWS Secrets Manager and other required resources.

3. **GitHub Repository**:
   Specify the repository where the self-hosted runner will be registered.

## Features

- Automates the setup of self-hosted runners for Unreal Engine projects on AWS ECS Fargate.
- Includes a webhook manager that dynamically scales the runners based on received webhook events.
  The manager script, [`github_webhook.py`](Fargate/Lambda_Functions/github_webhook.py), securely authenticates using the `github/webhook_token` from AWS Secrets Manager.
  Additionally, a custom GitHub Action utilizing this setup is available at [AWS Send Webhook](https://github.com/marketplace/actions/aws-send-webhook), which I developed to enhance this workflow.
- Manages the creation of runner images with a configurable Terraform variable:
  ```terraform
  variable "ecr_images" {
    description = "A map of ECR images to create"
    type = map(object({
      file    = string
      context = string
      name    = string
      tag     = string
    }))
  }
  ```
  See [variable.tf](Fargate/variables.tf) for more details.
- Includes a supervisor in each runner image to gracefully handle shutdown and scale down when no actions are running for 5 minutes.
- Implements CloudWatch monitoring to address worst-case scenarios. If multiple task failures occur within a 30-minute window, the service automatically scales down to 0 tasks, avoiding unnecessary costs and resource exhaustion.

## Usage

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/GuyErreich/Personal-IaC.git
   ```

2. **Verify AWS Secrets**:
   Ensure the secrets are correctly set up in AWS Secrets Manager:
   - `github/runner_token` with the key `Token`.
   - `github/webhook_token` with the key `Token`.

3. **Navigate to the Root Folder**:
   Use the root `taskfile` to deploy and manage the self-hosted runner.

4. **Run the Deployment Task**:
   Deploy the GitHub self-hosted runner for Fargate using the following task:
   ```bash
   task deploy
   ```

## Troubleshooting

- **Missing Tokens**:
  Verify that the tokens are stored correctly in AWS Secrets Manager under the specified secret names and keys.
- **Access Issues**:
  Ensure the IAM role or user associated with the AWS CLI has the necessary permissions to access Secrets Manager and other resources.

## Contributing

Contributions to improve or expand this setup are welcome! Submit issues or pull requests to share your ideas.

## License

This project is licensed under the MIT License. See the [LICENSE](../LICENSE) file for details.

