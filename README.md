# Terraform Module for Medusa on AWS

This Terraform module provides a flexible and scalable solution for deploying the [Medusa](https://medusajs.com/) e-commerce platform on Amazon Web Services (AWS). It allows users to create and manage all necessary infrastructure components, from basic deployments to more complex, customized configurations.

This module provides a complete set of composable sub-modules for each component of Medusa Infrastructure. These sub-modules can be used independently to deploy certain parts of infrastructure, but are combined inside the root module to deploy everything at once.

## Features

- **Modular Design:** The module is composed of sub-modules for each part of the infrastructure, providing a highly flexible and composable solution.
- **Comprehensive Resource Management:** Supports creation and management of essential Medusa infrastructure including VPC, subnets, ECR repositories, ElastiCache Redis, RDS PostgreSQL, backend, and storefront applications.
- **Customizable Configurations:** Allows for extensive customization of each component through a wide range of input variables.
- **Flexibility:** Supports both creating new infrastructure and integrating with existing AWS resources.
- **Ease of Use:** Provides sane defaults and clear examples for quick setup and deployment.
- **Scalable:** Designed to support both small and large-scale deployments of Medusa.

#
