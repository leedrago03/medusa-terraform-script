# Terraform Module for Medusa on AWS

This Terraform module provides a flexible and scalable solution for deploying the [Medusa](https://medusajs.com/) e-commerce platform on Amazon Web Services (AWS). It allows users to create and manage all necessary infrastructure components, from basic deployments to more complex, customized configurations.

This module provides a complete set of composable sub-modules for each component of Medusa Infrastructure. These sub-modules can be used independently to deploy certain parts of infrastructure, but are combined inside the root module to deploy everything at once.

## Features

-   **Modular Design:** The module is composed of sub-modules for each part of the infrastructure, providing a highly flexible and composable solution.
-   **Comprehensive Resource Management:** Supports creation and management of essential Medusa infrastructure including VPC, subnets, ECR repositories, ElastiCache Redis, RDS PostgreSQL, backend, and storefront applications.
-   **Customizable Configurations:** Allows for extensive customization of each component through a wide range of input variables.
-   **Flexibility:** Supports both creating new infrastructure and integrating with existing AWS resources.
-   **Ease of Use:** Provides sane defaults and clear examples for quick setup and deployment.
-   **Scalable:** Designed to support both small and large-scale deployments of Medusa.

---

# Medusa Terraform Deployment on AWS ECS with GitHub Actions

This project utilizes Terraform to deploy the Medusa open-source headless commerce platform backend on AWS ECS with Fargate, leveraging GitHub Actions for automated deployments.

## Table of Contents

-   [Prerequisites](#prerequisites)
-   [Initial Setup](#initial-setup)
    -   [Clone the Repository](#clone-the-repository)
    -   [Configure AWS Credentials](#configure-aws-credentials)
    -   [Set Required Variables](#set-required-variables)
-   [Running the Deployment](#running-the-deployment)
    -   [Push Changes](#push-changes)
    -   [Monitor Workflow](#monitor-workflow)
-   [Notes](#notes)
-   [Troubleshooting](#troubleshooting)
-   [Conclusion](#conclusion)

## Prerequisites

-   An active AWS account with the necessary IAM permissions to create and manage ECS, RDS, S3, and other required resources.
-   A GitHub repository with GitHub Actions configured for automated workflows.

## Initial Setup

### Clone the Repository

Clone your repository to your local machine:

```bash
git clone <your-repo-url>
cd <your-repo-directory>
### Configure AWS Credentials



1.  Navigate to your GitHub repository.
    
2.  Go to "Settings" > "Secrets and variables" > "Actions".
    
3.  Add the following secrets:
    
    *   AWS\_ACCESS\_KEY\_ID: Your AWS Access Key ID.
        
    *   AWS\_SECRET\_ACCESS\_KEY: Your AWS Secret Access Key.
        

**Important:** Ensure these credentials have the appropriate permissions for Terraform to create and manage AWS resources.

### Set Required Variables

Ensure that the following variables are set either in your GitHub Actions workflow file (.github/workflows/your-workflow.yml) or as repository secrets:

*   project: The name of your project.
    
*   environment: The target environment (e.g., dev, staging, prod).
    
*   owner: The owner or team responsible for the deployment.
    

You may need to set additional variables based on your Terraform configuration (e.g., VPC settings, RDS configurations, etc.).

Running the Deployment
----------------------

### Push Changes

Commit and push your changes to the main branch to trigger the GitHub Actions workflow:

Bash

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   git add .  git commit -m "Deploy Medusa Backend"  git push origin main   `

### Monitor Workflow

1.  Navigate to the "Actions" tab in your GitHub repository.
    
2.  Select the workflow run you triggered.
    
3.  Monitor the deployment process to ensure it completes successfully.
    
4.  Review the logs for any errors or warnings.
    

Notes
-----

*   **Plan Review:** Always review the Terraform plan output in the GitHub Actions logs before applying changes to avoid unintended modifications to your AWS infrastructure.
    
*   **Variable Configuration:** Ensure all required variables are correctly set in your Terraform configuration or passed as command-line arguments in the workflow.
    
*   **Environment Variables:** Carefully manage environment variables and secrets, especially for production deployments.
    

Troubleshooting
---------------

*   **Error Logs:** If you encounter issues, check the logs in GitHub Actions for detailed error messages.
    
*   **AWS Credentials:** Ensure your AWS credentials are correctly configured in GitHub Secrets.
    
*   **Terraform Errors:** Address any Terraform-specific errors based on the error messages.
    
*   **Resource Limits:** Verify that you have sufficient AWS resource limits in your region.
    

Conclusion
----------

This README.md provides a comprehensive guide to deploying your Medusa backend using Terraform and GitHub Actions. By following these instructions, you can automate your deployments and ensure consistent and reliable infrastructure management. Adjust the instructions as needed to fit your specific project requirements.
