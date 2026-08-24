# Automated Blue-Green Deployment

This is a production-style platform for a FastAPI URL shortener on AWS. Infrastructure is managed with Terraform, and delivery is keyless through GitHub OIDC. Releases use CodeDeploy blue-green deployments to ECS Fargate behind an ALB. The ALB terminates TLS through ACM and is protected by WAF. The platform runs three independent services an API, a background worker, and a dashboard backed by RDS, ElastiCache, and SQS, with a static frontend served through CloudFront.



## Project Overview

- **AWS ECS Fargate** — serverless, scalable compute hosting three services: API, background worker, and dashboard
- **Networking** — custom VPC across two Availability Zones, public/private subnets, route tables, security groups, ALB
- **AWS WAF** — filters web requests in front of the ALB for enhanced security
- **VPC Endpoints** — cost-efficient private access to ECR, SQS, S3, and CloudWatch, eliminating the need for a NAT gateway
- **PostgreSQL (RDS)** — stores URL mappings and click analytics
- **ElastiCache (Redis)** — in-memory cache in front of RDS on the redirect path
- **SQS** — decouples click events between the API and worker
- **TLS/DNS** — SSL certificates via ACM, DNS via Route 53, fully automated
- **CodeDeploy** — blue-green deployments to ECS Fargate for the API and dashboard
- **GitHub Actions** — CI/CD pipelines to build/scan/push images and deploy Terraform-provisioned infrastructure, authenticated via OIDC
- **Infrastructure as Code (Terraform)** — manages all infrastructure, fully automated

# Architecture


![LiveDemo](images/Architecture.gif)


# Live Demo 

![LiveDemo](images/LiveDemo.png) Production URL shortener running on ECS Fargate with HTTPS and WAF protection.


# Repository Structure


```text
Automated-Blue-Green-Deployment/
├── .github/
│   └── workflows/
│       ├── build-and-push.yml      # Build and push Docker image to ECR
│       ├── deploy.yml     # Deploy updated task definition to ECS
│       └── terraform.yml  # Validate, scan, and plan Terraform changes
├── app/
├── images/
├── service/
├── terraform/
│   ├── bootstrap/ 
│   ├── frontend/          # One-time setup: S3 backend, ECR, OIDC, IAM roles
│   ├── modules/
│   │   ├── acm/
│   │   ├── alb/
│   │   ├── codedeploy/
│   │   ├── ecr/
│   │   └── ecs/
│   │   └── elasticcache/
│   │   └── endpoint/
│   │   └── rds/
│   │   └── sqs/
│   │   └── vpc/
│   ├── main.tf
│   ├── output.tf
│   └── provider.tf
│   └── variables.tf
└── .gitignore
├── docker-compose.yml
├── README.md
```

# Network Componenets
![ResourceMap](images/AlbResourceMap.png)
![Endpoints](images/Endpoints.png)
![WAF_Rule](images/WAF_Rule.png)
![WAF](images/WAF.png)

# GitHub OIDC trust setup

![GitubOIDC](images/OIDC.png)
