kubectl scale deployment inflate --replicas 10
kubectl get node --selector=intent=apps -L kubernetes.io/arch -L node.kubernetes.io/instance-type -L karpenter.sh/nodepool -L topology.kubernetes.io/zone -L karpenter.sh/capacity-type
