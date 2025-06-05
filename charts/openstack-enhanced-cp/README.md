# Enhanced OpenStack ClusterTemplate for k0rdent

This custom ClusterTemplate extends the standard OpenStack template with enhanced networking, volume type support, and CCM CA certificate configuration.

## Features

- ✅ **Standard Control Plane**: Traditional control plane deployment
- ✅ **Volume Type Support**: Specify custom volume types for root volumes
- ✅ **Existing Network Support**: Use existing OpenStack networks and subnets
- ✅ **CCM CA Certificate**: Configure CA certificates for OpenStack Cloud Controller Manager
- ✅ **Enhanced Configuration**: More granular control over OpenStack resources

## Installation

### Step 1: Package the Helm Chart

```bash
# Package the chart
helm package custom-openstack-template/

# This will create: openstack-enhanced-cp-1.0.0.tgz
```

### Step 2: Add to k0rdent

Option A: Upload to Helm Repository (Recommended)
```bash
# Upload to your Helm repository
# Then update the HelmRepository in k0rdent to include your repo
```

Option B: Create directly in k0rdent cluster
```bash
# Copy the chart to the management cluster
kubectl create configmap openstack-enhanced-cp-chart \
  --from-file=openstack-enhanced-cp-1.0.0.tgz \
  -n kcm-system
```

### Step 3: Create ClusterTemplate Resource

```yaml
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterTemplate
metadata:
  name: openstack-enhanced-cp-1-0-0
  namespace: kcm-system
spec:
  helm:
    chartSpec:
      chart: openstack-enhanced-cp
      version: 1.0.0
      sourceRef:
        kind: HelmRepository
        name: your-helm-repo  # or ConfigMap reference
```

## Usage Examples

### Example 1: Using Existing Network (net-2 and subnet-net-2)

```yaml
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment
metadata:
  name: my-openstack-cluster
  namespace: kcm-system
spec:
  template: openstack-enhanced-cp-1-0-0
  credential: openstack-cluster-identity-cred
  config:
    # Basic cluster configuration
    controlPlaneNumber: 3
    workersNumber: 2
    
    # Control plane configuration
    controlPlane:
      flavor: "m1.large"
      image:
        filter:
          name: "ubuntu-22.04"
      sshKeyName: "my-keypair"
      rootVolume:
        size: 50
        volumeType: "ssd"  # Specify volume type
    
    # Worker configuration
    worker:
      flavor: "m1.medium"
      image:
        filter:
          name: "ubuntu-22.04"
      sshKeyName: "my-keypair"
      rootVolume:
        size: 50
        volumeType: "ssd"  # Specify volume type
    
    # Use existing network configuration
    networking:
      useExistingNetwork: true
      existingNetwork:
        name: "net-2"
      existingSubnet:
        name: "subnet-net-2"
      externalNetwork:
        filter:
          name: "external"
    
    # Identity configuration
    identityRef:
      name: "openstack-cluster-identity-cred"
      cloudName: "openstack"
      region: "RegionOne"
```

### Example 2: With CCM CA Certificate

```yaml
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment
metadata:
  name: my-secure-cluster
  namespace: kcm-system
spec:
  template: openstack-enhanced-cp-1-0-0  
  credential: openstack-cluster-identity-cred
  config:
    # ... other configuration ...
    
    # CCM CA Certificate configuration
    ccm:
      regional: true
      caCert:
        enabled: true
        source: "secret"  # or "configmap" or "inline"
        secretName: "openstack-ca-cert"
        key: "ca.crt"
    
    # Use existing network
    networking:
      useExistingNetwork: true
      existingNetwork:
        name: "net-2"
      existingSubnet:
        name: "subnet-net-2"
      externalNetwork:
        filter:
          name: "external"
```

### Example 3: Create New Network (Traditional)

```yaml
apiVersion: k0rdent.mirantis.com/v1beta1
kind: ClusterDeployment  
metadata:
  name: my-new-network-cluster
  namespace: kcm-system
spec:
  template: openstack-enhanced-cp-1-0-0
  credential: openstack-cluster-identity-cred
  config:
    # ... other configuration ...
    
    # Create new managed network
    networking:
      useExistingNetwork: false
      managedSubnets:
      - cidr: "10.6.0.0/24"
      externalNetwork:
        filter:
          name: "external"
```

## Configuration Reference

### Key Configuration Options

#### `networking.useExistingNetwork`
- **Type**: boolean
- **Default**: false
- **Description**: Whether to use existing network infrastructure

#### `networking.existingNetwork.name`
- **Type**: string
- **Description**: Name of existing OpenStack network to use

#### `networking.existingSubnet.name`
- **Type**: string  
- **Description**: Name of existing OpenStack subnet to use

#### `controlPlane.rootVolume.volumeType`
- **Type**: string
- **Description**: OpenStack volume type for control plane root volumes

#### `worker.rootVolume.volumeType`
- **Type**: string
- **Description**: OpenStack volume type for worker root volumes

#### `ccm.caCert.enabled`
- **Type**: boolean
- **Default**: false
- **Description**: Enable CA certificate configuration for OpenStack CCM

#### `ccm.caCert.source`
- **Type**: string
- **Options**: "secret", "configmap", "inline"
- **Description**: Source type for CA certificate

## Prerequisites

1. k0rdent management cluster with OpenStack provider installed
2. OpenStack credentials configured
3. Access to existing networks (if using existing network mode)
4. SSH keypairs configured in OpenStack
5. Appropriate flavors and images available

## Troubleshooting

### Common Issues

1. **Network not found**: Ensure the network name exists and is accessible
2. **Volume type not found**: Verify the volume type exists in your OpenStack deployment
3. **Insufficient quotas**: Check OpenStack quotas for instances, volumes, and networks
4. **CA certificate issues**: Ensure the certificate is properly formatted and accessible

### Validation

```bash
# Check template status
kubectl get clustertemplate openstack-enhanced-cp-1-0-0 -n kcm-system -o yaml

# Check cluster deployment
kubectl get clusterdeployment my-cluster -n kcm-system -o yaml

# Monitor cluster creation
kubectl get cluster,openstackcluster,k0scontrolplane -n kcm-system
``` 