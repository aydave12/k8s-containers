
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    metadata:
      labels:
        intent: apps
    spec:
      expireAfter: 720h
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand", "spot"]
        - key: karpenter.k8s.aws/instance-size
          operator: NotIn
          values: [nano, micro, small, medium, large]
        - key: "karpenter.k8s.aws/instance-generation"
          operator: Gt
          values: ["2"]
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 0s
---

apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiSelectorTerms:
    - alias: "bottlerocket@latest"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "eksspotworkshop"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "eksspotworkshop"
  role: "Karpenter-eksspotworkshop"
  tags:
    Name: karpenter.sh/nodepool/default
    NodeType: "karpenter-workshop"
    IntentLabel: "apps"
EOF

cat <<EOF > inflate-spot.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate-spot
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate-spot
  template:
    metadata:
      labels:
        app: inflate-spot
    spec:
      nodeSelector:
        intent: apps
        karpenter.sh/capacity-type: spot
      containers:
      - image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
        name: inflate-spot
        resources:
          requests:
            cpu: "1"
            memory: 256M
EOF
kubectl apply -f inflate-spot.yaml


#Multiple NodePools

cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    metadata:
      labels:
        intent: apps
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: karpenter.k8s.aws/instance-size
          operator: NotIn
          values: [nano, micro, small, medium, large]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64","arm64"]
        - key: "karpenter.k8s.aws/instance-generation"
          operator: Gt
          values: ["2"]
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiSelectorTerms:
    - alias: "al2023@latest"
  subnetSelectorTerms:          
    - tags:
        karpenter.sh/discovery: "eksspotworkshop"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "eksspotworkshop"
  role: "Karpenter-eksspotworkshop"
  tags:
    Name: karpenter.sh/nodepool/default
    NodeType: "karpenter-workshop"
    IntentLabel: "apps"
EOF

#We will now deploy a secondary NodePool named team1.

cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: team1
spec:
  template:
    metadata:
      labels:
        intent: apps
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: team1
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-size
          operator: NotIn
          values: [nano, micro, small, medium, large]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64","arm64"]
        - key: "karpenter.k8s.aws/instance-generation"
          operator: Gt
          values: ["2"]
      taints:
        - effect: NoSchedule
          key: team1
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: team1
spec:
  amiSelectorTerms:
    - alias: "bottlerocket@latest"
  subnetSelectorTerms:          
    - tags:
        karpenter.sh/discovery: "eksspotworkshop"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "eksspotworkshop"
  role: "Karpenter-eksspotworkshop"
  tags:
    Name: karpenter.sh/nodepool/team1
    NodeType: "karpenter-workshop"
    IntentLabel: "apps"
  userData:  |
    [settings.kubernetes]
    kube-api-qps = 30
    [settings.kubernetes.eviction-hard]
    "memory.available" = "20%"
EOF