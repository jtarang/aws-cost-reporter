# AWS Cost Report Lambda

## Description
AWS Cost Report Lambda is a serverless application designed to generate and report AWS cost data. This project automates the process of fetching AWS cost reports and provides insights into AWS expenditures.

## Features
- Serverless architecture using AWS Lambda
- CI/CD pipeline using GitHub Actions
- Automated linting and testing with Ruff
- Uses Terraform for infrastructure management
- Secure authentication via AWS IAM and Teleport Workload Identity

## Prerequisites
- Python 3.12+
- AWS account with necessary permissions
- GitHub repository with configured Secrets for AWS and Teleport authentication
- Terraform installed on local or CI environment

## Installation
1. Clone the repository:
   ```sh
   git clone https://github.com/your-repo/aws-cost-report-lambda.git
   cd aws-cost-report-lambda
   ```
2. Install dependencies using uv:
   ```sh
   curl -LsSf https://astral.sh/uv/install.sh | sh
   uv venv
   uv pip install .
   ```

## CI/CD Pipeline
The GitHub Actions workflow automates the following steps:
1. **Linting & Testing**: Runs Ruff linter on the source code.
2. **Building the Lambda Package**: Packages the code into a zip file.
3. **Deploying to AWS**: Uses Terraform to deploy the Lambda function to AWS.

### Running Tests Locally
To run the linting and testing process manually:
```sh
uv pip install ruff
uv run ruff check src
```

## Deployment
Deployment is automated through GitHub Actions but can be manually triggered using Terraform:
```sh
terraform init
terraform plan --var-file=tf/tfvars/local.dev.tfvars
terraform apply
```

## Configuration
Modify the `pyproject.toml` file to adjust dependencies and linting rules. Ensure AWS credentials and necessary permissions are set up in GitHub Secrets.

## License
This project is licensed under the MIT License.