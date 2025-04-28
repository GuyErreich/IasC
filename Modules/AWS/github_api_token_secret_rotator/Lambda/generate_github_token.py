import json
import boto3
import requests
import os
import base64
import jwt  # PyJWT library
import time
from utils import Logger
from cryptography.hazmat.primitives import serialization

# Initialize Logger
logger = Logger(name="GitHub-App-Secret-Rotation")

secrets_manager = boto3.client("secretsmanager")

GITHUB_OWNER = os.environ["GITHUB_OWNER"]
GITHUB_APP_ID = os.environ["GITHUB_APP_ID"]
GITHUB_INSTALLATION_ID = os.environ["GITHUB_INSTALLATION_ID"]
GITHUB_PRIVATE_KEY_SECRET_ARN = os.environ["GITHUB_PRIVATE_KEY_SECRET_ARN"]
SECRET_CONFIG = json.loads(os.environ["SECRET_CONFIG"])
SECRET_PREFIX = os.environ["SECRET_PREFIX"]

GITHUB_API_URL = f"https://api.github.com/app/installations/{GITHUB_INSTALLATION_ID}/access_tokens"

def get_github_app_jwt():
    """Generate a JWT (JSON Web Token) for GitHub App authentication."""
    try:
        # Retrieve private key from AWS Secrets Manager
        response = secrets_manager.get_secret_value(SecretId=GITHUB_PRIVATE_KEY_SECRET_ARN)
        private_key_pem = response["SecretString"]

        # Load private key
        private_key = serialization.load_pem_private_key(
            private_key_pem.encode(), password=None
        )

        # JWT payload
        payload = {
            "iat": int(time.time()),  # Issued at time
            "exp": int(time.time()) + (10 * 60),  # Expiration time (10 minutes)
            "iss": GITHUB_APP_ID,  # GitHub App ID
        }

        # Create JWT
        jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

        logger.info("Generated GitHub App JWT successfully.")
        return jwt_token
    except Exception as e:
        logger.error(f"Failed to generate GitHub App JWT: {str(e)}")
        raise

def get_github_installation_token():
    """Obtain an installation access token for the GitHub App."""
    jwt_token = get_github_app_jwt()

    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Accept": "application/vnd.github.v3+json",
    }

    response = requests.post(GITHUB_API_URL, headers=headers)

    if response.status_code != 201:
        logger.error(f"Failed to get GitHub installation token: {response.text}")
        raise Exception(f"Failed to get GitHub installation token: {response.text}")

    installation_token = response.json()["token"]
    logger.info("Successfully obtained GitHub installation token.")
    return installation_token

def get_secret_name(secret_arn):
    """Retrieves the actual secret name from AWS Secrets Manager and removes prefix."""
    try:
        response = secrets_manager.describe_secret(SecretId=secret_arn)
        full_secret_name = response["Name"]
        logger.info(f"Retrieved secret name: {full_secret_name}")

        # Remove the prefix from the secret name
        if full_secret_name.startswith(SECRET_PREFIX):
            secret_name = full_secret_name[len(SECRET_PREFIX):]
        else:
            secret_name = full_secret_name

        logger.info(f"Processed secret name after removing prefix: {secret_name}")
        return secret_name
    except Exception as e:
        logger.error(f"Error retrieving secret name for {secret_arn}: {str(e)}")
        raise

def create_github_app_token(secret_name, permissions):
    """Creates a new installation token using GitHub App permissions."""
    logger.info(f"Creating a new GitHub App token for secret: {secret_name}")

    # Get an installation token
    installation_token = get_github_installation_token()

    headers = {
        "Authorization": f"Bearer {installation_token}",
        "Accept": "application/vnd.github.v3+json",
    }

    token_data = {
        "permissions": permissions,
        "repository_ids": [],  # Optionally limit to specific repositories
    }

    response = requests.post(GITHUB_API_URL, headers=headers, json=token_data)

    if response.status_code != 201:
        logger.error(f"Failed to create GitHub App token: {response.text}")
        raise Exception(f"Failed to create GitHub App token: {response.text}")

    logger.info(f"Successfully created new GitHub App token for {secret_name}")
    return response.json()["token"]

def rotate_secret(secret_name, config):
    """Rotates a single GitHub App token and updates AWS Secrets Manager."""
    github_secret_name = config["github_secret_name"]
    github_permissions = config.get("github_permissions", {})

    # Create GitHub App Token with specific permissions
    new_secret = create_github_app_token(github_secret_name, github_permissions)

    # Store the token in AWS Secrets Manager
    aws_secret_path = f"{SECRET_PREFIX}{secret_name}"  # Add prefix back when storing
    secrets_manager.put_secret_value(SecretId=aws_secret_path, SecretString=new_secret)

    logger.info(f"Stored new GitHub App token in AWS Secrets Manager under {aws_secret_path}")
    logger.info(f"Secret rotation successful for {secret_name}")

def lambda_handler(event, context):
    """Handles the AWS Lambda event for secret rotation."""
    logger.info(f"Received event: {json.dumps(event)}")

    # If triggered by AWS Secrets Manager, rotate only the relevant secret
    if "SecretId" in event:
        secret_arn = event["SecretId"]
        secret_name = get_secret_name(secret_arn)

        if secret_name not in SECRET_CONFIG:
            logger.error(f"Secret {secret_name} is not found in SECRET_CONFIG.")
            return {"error": f"Secret {secret_name} not found in configuration"}

        rotate_secret(secret_name, SECRET_CONFIG[secret_name])
        return {"status": f"Secret {secret_name} rotated successfully"}

    # If triggered manually, rotate all secrets
    for secret_name, config in SECRET_CONFIG.items():
        try:
            rotate_secret(secret_name, config)
        except Exception as e:
            logger.error(f"Error rotating secret {secret_name}: {str(e)}")

    return {"status": "All secrets rotated successfully"}
