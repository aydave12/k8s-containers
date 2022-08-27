resource "aws_eks_cluster" "aws_eks_cluster-000ca2bb" {
  provider = aws.eu-central-1

  role_arn = aws_iam_role.iam_role.arn
  name     = "eks_cluster"

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }

  vpc_config {
    public_access_cidrs     = concat([var.authorized_source_ranges], [aws_eip.nat_a.public_ip, aws_eip.nat_b.public_ip])
    endpoint_public_access  = true
    endpoint_private_access = true
    security_group_ids = [
      aws_security_group.sg_eks_cluster.id,
    ]
    subnet_ids = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id,
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment-03f3d617" {
  provider = aws.eu-central-1

  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment-0928c6b1" {
  provider = aws.eu-central-1

  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_eks_node_group" "aws_eks_node_group-115fff76" {
  provider = aws.eu-central-1

  node_role_arn   = aws_iam_role.node_group.arn
  node_group_name = "public"
  cluster_name    = aws_eks_cluster.eks_cluster.name

  instance_types = [
    "t3.medium",
  ]

  labels {
    type = "public"
  }

  scaling_config {
    min_size     = "1"
    max_size     = "3"
    desired_size = "1"
  }

  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "EKS-Cluster"
  }
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment-1180b8c5" {
  provider = aws.eu-central-1

  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "aws_iam_role-11e70291" {
  provider = aws.eu-central-1

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
  EOF

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
  }
}

resource "aws_vpc" "aws_vpc-2fddb57e" {
  provider = aws.eu-central-1

  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  cidr_block           = var.vpc_cidr_block

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }
}

resource "aws_route_table" "aws_route_table-30dfd333" {
  provider = aws.eu-central-1

  vpc_id = aws_vpc.default_vpc.id

  route {
    gateway_id = aws_internet_gateway.default_internet_gtw.id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }
}

resource "aws_route_table_association" "aws_route_table_association-35d2886a" {
  provider = aws.eu-central-1

  route_table_id = aws_route_table.private_route_a.id
  gateway_id     = aws_subnet.private_a.id
}

resource "aws_iam_role_policy" "aws_iam_role_policy-4c8b8065" {
  provider = aws.eu-central-1

  role = aws_iam_role.node_group.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
  name = "eks-cluster-auto-scaler"
}

resource "aws_internet_gateway" "aws_internet_gateway-54e72658" {
  provider = aws.eu-central-1

  vpc_id = aws_vpc.default_vpc.id

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }
}

resource "aws_nat_gateway" "aws_nat_gateway-5ba0232f" {
  provider = aws.eu-central-1

  subnet_id     = aws_subnet.private_a.id
  allocation_id = aws_eip.nat_a.id

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }
}

resource "aws_route_table_association" "aws_route_table_association-6df7421c" {
  provider = aws.eu-central-1

  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.route_table_internet.id
}

resource "aws_eks_node_group" "aws_eks_node_group-723d8742" {
  provider = aws.eu-central-1

  node_role_arn   = aws_iam_role.node_group.arn
  node_group_name = "private"
  cluster_name    = aws_eks_cluster.eks_cluster.name

  instance_types = [
    "m5.xlarge",
  ]

  labels {
    type = "private"
  }

  scaling_config {
    min_size     = "2"
    max_size     = "4"
    desired_size = "2"
  }

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }
}

resource "aws_eip" "aws_eip-72baf55a" {
  provider = aws.eu-central-1

  vpc = true

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }
}

resource "aws_subnet" "aws_subnet-85d3ce34" {
  provider = aws.eu-central-1

  vpc_id                  = aws_vpc.default_vpc.id
  map_public_ip_on_launch = true
  cidr_block              = var.cidr_block_public_a
  availability_zone       = "eu-central-1b"

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }
}

resource "aws_security_group" "aws_security_group-902bcf54" {
  provider = aws.eu-central-1

  vpc_id      = aws_vpc.aws_vpc-2fddb57e.id
  name        = "eks_cluster/ControlPlaneSecurityGroup"
  description = "Communication between the control plane and worker nodegroups"

  egress {
    to_port   = "0"
    protocol  = "-1"
    from_port = "0"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "gitlab_eks_cluster/ControlPlaneSecurityGroup"
  }
}

resource "aws_default_security_group" "aws_default_security_group-9b91d8c1" {
  provider = aws.eu-central-1

  vpc_id = aws_vpc.default_vpc.id

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment-ab07ead1" {
  provider = aws.eu-central-1

  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment-ab0bc669" {
  provider = aws.eu-central-1

  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_subnet" "aws_subnet-dc62cb9a" {
  provider = aws.eu-central-1

  vpc_id                  = aws_vpc.default_vpc.id
  map_public_ip_on_launch = false
  cidr_block              = var.cidr_block_private_a
  availability_zone       = "eu-central-1a"

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
    Name     = "Gitlab"
  }
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment-dfc3b3cd" {
  provider = aws.eu-central-1

  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_route_table" "aws_route_table-e8508d10" {
  provider = aws.eu-central-1

  vpc_id = aws_vpc.default_vpc.id

  route {
    gateway_id = aws_nat_gateway.gtw_a.id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
  }
}

resource "aws_iam_openid_connect_provider" "aws_iam_openid_connect_provider-f14b9e17" {
  provider = aws.eu-central-1

  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    data.tls_certificate.cert.certificates[0].sha1_fingerprint,
  ]
}

resource "aws_iam_role" "aws_iam_role-fa0eef19" {
  provider = aws.eu-central-1

  name = "eks_node_group"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = {
    env      = "development"
    archUUID = "d7873fd8-8f4d-43b7-b9f2-1534cbd8c848"
  }
}

resource "aws_security_group_rule" "aws_security_group_rule-fac77768" {
  provider = aws.eu-central-1

  type                     = "ingress"
  to_port                  = "0"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.sg_eks_cluster.id
  protocol                 = "-1"
  from_port                = "0"
  description              = "Allow unmanaged nodes to communicate with control plane (all ports)"
}