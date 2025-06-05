# Enhanced OpenStack Hosted Control Plane Template for k0rdent

This custom ClusterTemplate extends the standard OpenStack hosted control plane approach with enhanced networking, volume type support, and CCM CA certificate configuration. The control plane runs on the management cluster while worker nodes are deployed on OpenStack.

## Features

- ✅ **Hosted Control Plane**: Control plane runs on k0rdent management cluster
- ✅ **Volume Type Support**: Specify custom volume types for worker volumes  
- ✅ **Existing Network Support**: Use existing OpenStack networks and subnets
- ✅ **CCM CA Certificate**: Configure CA certificates for OpenStack Cloud Controller Manager
- ✅ **Enhanced Configuration**: More granular control over OpenStack resources
- ✅ **Cost Optimization**: Reduced infrastructure costs by hosting control plane centrally

## Architecture

```
┌─────────────────────────────────┐     ┌─────────────────────────────────┐
│       Management Cluster       │     │          OpenStack              │
│  (k0rdent + Control Planes)    │     │      (Worker Nodes)             │
│                                 │     │                                 │
│  ┌─────────────────────────────┐│     │  ┌─────────────────────────────┐│
│  │  K0smotronControlPlane      ││     │  │       Worker Node 1         ││
│  │  - API Server               ││◄────┤  │   ┌─────────────────────┐   ││
│  │  - Controller Manager      ││     │  │   │      kubelet        │   ││
│  │  - Scheduler                ││     │  │   │   kube-proxy       │   ││
│  │  - etcd                     ││     │  │   └─────────────────────┘   ││
│  └─────────────────────────────┘│     │  └─────────────────────────────┘│
│                                 │     │                                 │
│  ┌─────────────────────────────┐│     │  ┌─────────────────────────────┐│
│  │    LoadBalancer Service     ││     │  │       Worker Node N         ││
│  │  - API: 6443               ││     │  │   ┌─────────────────────┐   ││
│  │  - Konnectivity: 8132      ││     │  │   │      kubelet        │   ││
│  └─────────────────────────────┘│     │  │   │   kube-proxy       │   ││
└─────────────────────────────────┘     │  │   └─────────────────────┘   ││
                                        │  └─────────────────────────────┘│
                                        └─────────────────────────────────┘
```

## Installation

### Step 1: Package the Chart

```bash
# Package the chart
helm package openstack-hosted-cp-template/

# This will create: openstack-enhanced-hosted-cp-1.0.0.tgz
```

### Step 2: Add to k0rdent Management Cluster

```bash
# Copy chart to management cluster
export KUBECONFIG='/Users/jhennig/Desktop/k0rdent/OpenStack internal/kubeconfig'

# Create a ConfigMap for the chart
kubectl create configmap openstack-enhanced-hosted-cp-chart \
  --from-file=openstack-enhanced-hosted-cp-1.0.0.tgz \
  -n kcm-system
```

### Step 3: Create ClusterTemplate Resource

```yaml
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterTemplate
metadata:
  name: openstack-enhanced-hosted-cp-1-0-0
  namespace: kcm-system
spec:
  helm:
    chartSpec:
      chart: openstack-enhanced-hosted-cp
      version: 1.0.0
      sourceRef:
        kind: ConfigMap
        name: openstack-enhanced-hosted-cp-chart
```

## Usage Examples

### Example 1: Using Existing Network (net-2 and subnet-net-2)

```yaml
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment
metadata:
  name: my-hosted-cluster
  namespace: kcm-system
spec:
  template: openstack-enhanced-hosted-cp-1-0-0
  credential: openstack-cluster-identity-cred
  config:
    # Hosted control plane parameters
    managementClusterName: "k0rdent-management"
    workersNumber: 3
    
    # Worker configuration with enhanced volume support
    worker:
      flavor: "m1.medium"
      image:
        filter:
          name: "ubuntu-22.04"
      sshKeyName: "your-keypair"
      rootVolume:
        size: 50
        volumeType: "ssd"  # Specify volume type
    
    # Use existing network configuration
    useExistingNetwork: true
    existingNetwork:
      name: "net-2"
    existingSubnet:
      name: "subnet-net-2"
      
    # External network configuration
    externalNetwork:
      filter:
        name: "external"
    
    # Identity configuration
    identityRef:
      name: "openstack-cluster-identity-cred"
      cloudName: "openstack"
      region: "RegionOne"
    
    # K0smotron service configuration
    k0smotron:
      service:
        type: LoadBalancer
        apiPort: 6443
        konnectivityPort: 8132
```

### Example 2: With CCM CA Certificate

```yaml
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment
metadata:
  name: my-secure-hosted-cluster
  namespace: kcm-system
spec:
  template: openstack-enhanced-hosted-cp-1-0-0
  credential: openstack-cluster-identity-cred
  config:
    # ... other configuration ...
    
    # CCM CA Certificate configuration
    ccmCaCert:
      enabled: true
      source: "secret"
      secretName: "openstack-ca-cert"
      key: "ca.crt"
      
    # Use existing network
    useExistingNetwork: true
    existingNetwork:
      name: "net-2"
    existingSubnet:
      name: "subnet-net-2"
```

## Configuration Reference

### Key Configuration Options

#### `managementClusterName`
- **Type**: string
- **Required**: true
- **Description**: Name of the management cluster hosting the control plane

#### `workersNumber`
- **Type**: integer
- **Default**: 2
- **Description**: Number of worker nodes to deploy on OpenStack

#### `useExistingNetwork`
- **Type**: boolean
- **Default**: false
- **Description**: Whether to use existing network infrastructure

#### `worker.rootVolume.volumeType`
- **Type**: string
- **Description**: OpenStack volume type for worker root volumes

#### `k0smotron.service.type`
- **Type**: string
- **Default**: LoadBalancer
- **Options**: ClusterIP, NodePort, LoadBalancer
- **Description**: Service type for API access

#### `ccmCaCert.enabled`
- **Type**: boolean
- **Default**: false
- **Description**: Enable CA certificate configuration for OpenStack CCM

## Benefits of Hosted Control Plane

### 🏗️ **Architectural Advantages**
- **Centralized Management**: All control planes managed from one location
- **High Availability**: Control plane HA handled by management cluster
- **Simplified Operations**: No need to manage control plane infrastructure per cluster
- **Consistency**: Standardized control plane configuration across clusters

### 💰 **Cost Optimization**
- **Reduced Infrastructure**: No need for control plane VMs per cluster
- **Better Resource Utilization**: Management cluster handles multiple control planes
- **Lower Operational Overhead**: Fewer machines to manage and maintain

### 🔧 **Operational Benefits**
- **Faster Deployment**: No need to provision control plane infrastructure
- **Easier Scaling**: Add worker capacity without control plane concerns
- **Simplified Networking**: Control plane accessible via management cluster services
- **Unified Monitoring**: All control planes visible from management cluster

## Comparison: Standard vs Hosted Control Plane

| Aspect | Standard Control Plane | Hosted Control Plane |
|--------|----------------------|---------------------|
| **Control Plane Location** | On OpenStack instances | On management cluster |
| **Infrastructure Cost** | Higher (CP + Worker VMs) | Lower (Worker VMs only) |
| **Management Complexity** | Per-cluster CP management | Centralized management |
| **HA Configuration** | Per-cluster HA setup | Management cluster HA |
| **Deployment Speed** | Slower (CP provisioning) | Faster (no CP provisioning) |
| **Network Requirements** | Internal connectivity | Management-to-worker connectivity |

## Prerequisites

1. k0rdent management cluster with OpenStack provider installed
2. K0smotron installed on management cluster
3. OpenStack credentials configured
4. Access to existing networks (if using existing network mode)
5. SSH keypairs configured in OpenStack
6. Appropriate flavors and images available

## Troubleshooting

### Common Issues

1. **Service connectivity**: Ensure LoadBalancer service is accessible from workers
2. **Network connectivity**: Verify management cluster can reach OpenStack network
3. **Certificate issues**: Check CCM CA certificate configuration if using custom certs
4. **Resource quotas**: Verify OpenStack quotas for instances and volumes

### Validation

```bash
# Check template status
kubectl get clustertemplate openstack-enhanced-hosted-cp-1-0-0 -n kcm-system -o yaml

# Check hosted control plane
kubectl get k0smotroncontrolplane -n kcm-system

# Check cluster deployment
kubectl get clusterdeployment my-hosted-cluster -n kcm-system -o yaml

# Monitor cluster creation
kubectl get cluster,openstackcluster,k0smotroncontrolplane -n kcm-system
```

## Next Steps

After successful deployment:
1. **Access the cluster**: Use the generated kubeconfig
2. **Validate connectivity**: Ensure worker nodes can reach the hosted control plane
3. **Deploy workloads**: Test application deployment and functionality
4. **Monitor resources**: Check resource utilization on both management and worker clusters 