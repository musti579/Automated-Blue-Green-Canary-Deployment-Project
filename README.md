# Automated Blue-Green Canary Deployment

This is a production-style platform for a FastAPI URL shortener on AWS. Infrastructure is managed with Terraform, and delivery is keyless through GitHub OIDC. Releases use CodeDeploy blue-green deployments to ECS Fargate behind an ALB. The ALB terminates TLS through ACM and is protected by WAF. The platform runs three independent services an API, a background worker, and a dashboard backed by RDS, ElastiCache, and SQS, with a static frontend served through CloudFront.

# Architecture




# Live Demo 

![LiveDemo](images/LiveDemo.png)


