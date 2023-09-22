locals {
  cluster_name = "eksinfra"
}

#Define VPC module to create vpc, public and private subnets, route tables, nat gateways.
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs            = var.azs            #provie the list of az's
  public_subnets = var.public_subnets #provide the list of cidr blocks

  public_subnet_tags_per_az = {
    us-east-1a = {
      Name = "${local.name}-public-1"
    },
    us-east-1b = {
      Name = "${local.name}-public-2"
    },
    us-east-1c = {
      Name = "${local.name}-public-3"
    }
  }

  public_route_table_tags = {
    Name = "${local.name}-public-routes"
  }

  private_subnets = var.private_subnets #provide the list of cidr blocks

  private_subnet_tags_per_az = {
    us-east-1a = {
      Name = "${local.name}-private-1",
    },
    us-east-1b = {
      Name = "${local.name}-private-2",
    },
    us-east-1c = {
      Name = "${local.name}-private-3"
    }
  }

  private_route_table_tags = {
    Name = "${local.name}-private-routes"
  }

  #Create one NAT Gateway per AZ and associate it to elastic IP
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  reuse_nat_ips          = true
  external_nat_ip_ids    = aws_eip.nat.*.id

  tags = {
    Name        = "${local.name}"
    Environment = "${var.environment}"
  }
}

#Create the Elastic IP's for nat gateway
resource "aws_eip" "nat" {
  count = var.eip_count
  vpc   = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.27"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
  control_plane_subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium", "c5.large", "t3.micro"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

data "tls_certificate" "eks" {
  url = module.eks.cluster_oidc_issuer_url

  depends_on = [ module.eks.cluster_id ]
}

resource "aws_iam_role" "route53_full_access_role" {
  name = "Route53FullAccessRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "route53_full_access_policy" {
  name        = "Route53FullAccessPolicy"
  description = "IAM policy with full access to Route 53 hosted zones"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Route53FullAccess",
        Effect = "Allow",
        Action = "route53:*",
        Resource = "*",
      },
    ],
  })
}

resource "aws_iam_policy_attachment" "attach_route53_policy" {
  name       = "AttachRoute53Policy"
  policy_arn = aws_iam_policy.route53_full_access_policy.arn
  roles      = [aws_iam_role.route53_full_access_role.name]
}

data "aws_iam_policy" "ekscluster" {
  name = "AmazonEKSClusterPolicy"
}

resource "aws_iam_policy_attachment" "attach_eks_policy" {
  name       = "AttacheksPolicy"
  policy_arn = data.aws_iam_policy.ekscluster.arn
  roles      = [aws_iam_role.route53_full_access_role.name]
}