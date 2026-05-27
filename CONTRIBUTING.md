# Contributing to AWS Data Platform

Thank you for your interest in contributing to this project. This document explains how to set up the development environment and contribute effectively.

---

## Prerequisites

Before contributing, make sure you have the following installed:

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI v2](https://aws.amazon.com/cli/) configured with valid credentials
- [Git](https://git-scm.com/)

---

## Getting Started

**1. Fork and clone the repository**

```bash
git clone https://github.com/YOUR-USERNAME/aws-data-platform.git
cd aws-data-platform
```

**2. Create a feature branch**

```bash
git checkout -b feat/your-feature-name
```

**3. Initialize Terraform**

```bash
terraform init
```

**4. Make your changes**

Follow the project structure — each concern belongs in its own module under `modules/`.

---

## Code Standards

**Terraform formatting:**

All Terraform files must be formatted before committing:

```bash
terraform fmt -recursive
```

**Terraform validation:**

All Terraform files must pass validation:

```bash
terraform validate
```

The CI pipeline runs both checks automatically on every push. Pull requests with formatting or validation errors will not be merged.

**Naming conventions:**
- Resources: `${var.project_name}-resource-type` — e.g. `ojong-data-platform-ec2`
- Variables: lowercase with underscores — e.g. `db_instance_class`
- Outputs: lowercase with underscores — e.g. `ec2_public_ip`

**Tagging:**

Every resource must include these tags:

```hcl
tags = {
  Project     = var.project_name
  Environment = var.environment
  ManagedBy   = "Terraform"
}
```

---

## Adding a New Module

1. Create a new folder under `modules/your-module-name/`
2. Add `main.tf`, `variables.tf` and `outputs.tf`
3. Call the module from the root `main.tf`
4. Document all variables with descriptions
5. Document all outputs with descriptions

---

## Testing Your Changes

Always run a plan before applying:

```bash
terraform plan
```

Review every resource in the plan output before typing `yes`.

After testing, destroy all resources to avoid charges:

```bash
terraform destroy
```

---

## Submitting a Pull Request

1. Run `terraform fmt -recursive` and `terraform validate`
2. Commit with a clear message following this format:

```
type: short description

- Detail 1
- Detail 2
```

Types: `feat`, `fix`, `docs`, `refactor`, `ci`

3. Push your branch and open a pull request against `main`
4. Describe what you changed and why

---

## Security

- Never commit `terraform.tfvars` — it contains sensitive credentials
- Never commit `.terraform/` or `*.tfstate` files
- Never hardcode AWS credentials in any `.tf` file
- Always use IAM roles with least privilege

---

## Author

**Ojong Bessong NKONGHO**
Data Engineering Student — DSTI School of Engineering, Paris

[![LinkedIn](https://img.shields.io/badge/LinkedIn-nkongho--ojong-0077B5?style=flat&logo=linkedin)](https://linkedin.com/in/nkongho-ojong)
[![GitHub](https://img.shields.io/badge/GitHub-OjongBessongNKONGHO-181717?style=flat&logo=github)](https://github.com/OjongBessongNKONGHO)