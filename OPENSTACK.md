# k0rdent/kcm (out-of-tree), OpenStack Provider

## Install `k0rdent/kcm` into Kubernetes cluster

```bash
helm install kcm oci://ghcr.io/k0rdent/kcm/charts/kcm --version 1.0.0 -n kcm-system --create-namespace \
  --set controller.enableTelemetry=false \
  --set velero.enabled=false
```

## Wait for `Management` object readiness

```bash
kubectl wait --for=condition=Ready=True management/kcm --timeout=300s
```

## OpenStack Provider Options

This provider offers two deployment models:

### 1. Enhanced Control Plane (`openstack-enhanced-cp`)
- Full control plane nodes running on OpenStack
- Enhanced networking and volume type support
- Suitable for production workloads

### 2. Hosted Control Plane (`openstack-hosted-cp`)
- Control plane runs within the management cluster
- Worker nodes deployed on OpenStack
- Suitable for cost optimization and multi-tenancy

## Create OpenStack credentials

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: openstack-config
  namespace: kcm-system
  labels:
    k0rdent.mirantis.com/component: "kcm"
stringData:
  # OpenStack credentials from clouds.yaml
  clouds.yaml: |
    clouds:
      openstack:
        auth:
          auth_url: https://your-openstack-endpoint:5000/v3
          username: your-username
          password: your-password
          project_name: your-project
          user_domain_name: Default
          project_domain_name: Default
        region_name: RegionOne
        interface: public
        identity_api_version: 3
---
apiVersion: k0rdent.mirantis.com/v1beta1
kind: Credential
metadata:
  name: openstack-cluster-identity-cred
  namespace: kcm-system
spec:
  description: OpenStack credentials
  identityRef:
    apiVersion: v1
    kind: Secret
    name: openstack-config
    namespace: kcm-system
EOF
```

## Option 1: Deploy Enhanced Control Plane Cluster

```bash
kubectl apply -f - <<EOF
---
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment
metadata:
  name: openstack-enhanced-demo
  namespace: kcm-system
spec:
  template: openstack-enhanced-cp-1-0-0
  credential: openstack-cluster-identity-cred
  config:
    region: RegionOne
    identityRef:
      name: openstack-config
      cloudName: openstack
    # Enhanced: Use existing network (optional)
    useExistingNetwork: false
    # For existing networks, specify:
    # useExistingNetwork: true
    # existingNetwork:
    #   name: "existing-network-name"
    # existingSubnet:
    #   name: "existing-subnet-name"
    externalNetwork:
      filter:
        name: "public"
    controlPlane:
      replicas: 3
      flavor: "m1.large"
      image:
        filter:
          name: "ubuntu-22.04"
      sshKeyName: "your-ssh-key"
      # Enhanced: Volume type support
      rootVolume:
        size: 50
        volumeType: "ssd"
    worker:
      replicas: 2
      flavor: "m1.medium"
      image:
        filter:
          name: "ubuntu-22.04"
      sshKeyName: "your-ssh-key"
      rootVolume:
        size: 50
        volumeType: "ssd"
    # Enhanced: CCM CA certificate (optional)
    ccmCaCert:
      enabled: false
    # Regional CCM support
    ccmRegional: true
EOF
```

## Option 2: Deploy Hosted Control Plane Cluster

```bash
kubectl apply -f - <<EOF
---
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment
metadata:
  name: openstack-hosted-demo
  namespace: kcm-system
spec:
  template: openstack-hosted-cp-1-0-0
  credential: openstack-cluster-identity-cred
  config:
    region: RegionOne
    identityRef:
      name: openstack-config
      cloudName: openstack
    workersNumber: 2
    managementClusterName: "management"
    # Enhanced: Use existing network (optional)
    useExistingNetwork: false
    externalNetwork:
      filter:
        name: "public"
    worker:
      flavor: "m1.medium"
      image:
        filter:
          name: "ubuntu-22.04"
      sshKeyName: "your-ssh-key"
      # Enhanced: Volume type support
      rootVolume:
        size: 50
        volumeType: "ssd"
    k0smotron:
      service:
        type: LoadBalancer
        apiPort: 6443
        konnectivityPort: 8132
    # Enhanced: CCM CA certificate (optional)
    ccmCaCert:
      enabled: false
    # Regional CCM support
    ccmRegional: true
EOF
```

## Steps to debug child OpenStack cluster deployment:

#### Describe cluster status

```bash
# For enhanced control plane
clusterctl describe cluster openstack-enhanced-demo -n kcm-system

# For hosted control plane
clusterctl describe cluster openstack-hosted-demo -n kcm-system
```

#### Get `ClusterDeployment` objects

```bash
kubectl get cld -A
```

#### Get `Machine` objects

```bash
kubectl get machine -A
```

#### Get OpenStack-specific objects

```bash
kubectl get openstackcluster,openstackmachine -A
```

#### Get child cluster `kubeconfig`

```bash
# For enhanced control plane
clusterctl get kubeconfig openstack-enhanced-demo -n kcm-system > openstack-enhanced-demo.kubeconfig

# For hosted control plane
clusterctl get kubeconfig openstack-hosted-demo -n kcm-system > openstack-hosted-demo.kubeconfig
```

#### Test `kubeconfig`

```bash
# For enhanced control plane
kubectl --kubeconfig=./openstack-enhanced-demo.kubeconfig get nodes -o wide

# For hosted control plane
kubectl --kubeconfig=./openstack-hosted-demo.kubeconfig get nodes -o wide
```

## Enhanced Features

### Existing Network Support

Both templates support using existing OpenStack networks:

```yaml
useExistingNetwork: true
existingNetwork:
  name: "my-existing-network"
  # or use ID instead:
  # id: "network-uuid"
existingSubnet:
  name: "my-existing-subnet"
  # or use ID instead:
  # id: "subnet-uuid"
```

### Volume Type Configuration

Configure specific volume types for better performance:

```yaml
rootVolume:
  size: 50
  volumeType: "ssd"  # or "hdd", "nvme", etc.
  availabilityZone: "zone-1"
```

### CCM CA Certificate Support

For environments with custom CA certificates:

```yaml
ccmCaCert:
  enabled: true
  source: "secret"  # or "configmap", "inline"
  secretName: "openstack-ca-cert"
  key: "ca.crt"
```

## Troubleshooting

#### Check OpenStack provider logs

```bash
kubectl logs -n kcm-system -l cluster.x-k8s.io/provider=infrastructure-openstack
```

#### Verify OpenStack credentials

```bash
kubectl get secret openstack-config -n kcm-system -o yaml
```

#### Check cluster events

```bash
kubectl get events -n kcm-system --sort-by='.lastTimestamp'
``` 