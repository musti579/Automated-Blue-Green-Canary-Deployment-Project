terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider (default region for everything else)
provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      Project = "ecs2"
    }
  }
}

# Second provider, specifically for CloudFront certs which must live in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket       = "mustafa-devopsv2-tfstate"
    key          = "global/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
}