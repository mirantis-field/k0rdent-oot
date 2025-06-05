# k0rdent/kcm (out-of-tree)

This repository contains out-of-tree Helm chart(s) for [k0rdent/kcm](https://docs.k0rdent.io/stable/quickstarts/quickstart-1-mgmt-node-and-cluster/#install-k0rdent). 

More information on how to work with Bring Your Own Templates can be found in the [docs](https://docs.k0rdent.io/1.0.0/reference/template/template-byo/).

## Quick Start

### Prerequisites

- A running k0rdent management cluster
- `kubectl` configured to access your management cluster
- Appropriate cloud provider credentials configured

### Add the Out-of-Tree HelmRepository

Create a HelmRepository resource to point k0rdent to this out-of-tree chart registry:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: k0rdent-oot
  namespace: kcm-system
spec:
  interval: 10m
  type: oci
  url: oci://ghcr.io/k0rdent-oot/oot/charts
```

Apply the HelmRepository:

```bash
kubectl apply -f helmrepository.yaml
```

Verify the repository is ready:

```bash
kubectl get helmrepository -n kcm-system k0rdent-oot
```

## Provider-Specific Configuration

For detailed configuration options and examples for each provider, see the provider-specific documentation:

- [Hetzner Configuration Guide](HETZNER.md)
- [KubeVirt Configuration Guide](KUBEVIRT.md) 
- [OpenStack Configuration Guide](OPENSTACK.md)

## Development

### Adding New Templates

1. Create your Helm chart in the `charts/` directory
2. Follow the existing chart structure and conventions
3. Add appropriate metadata and annotations
4. Test the chart locally using `helm template`
5. Update this README with template information

### Chart Conventions

- Charts must include the `k0rdent.mirantis.com/type: deployment` annotation
- Follow the naming convention: `<provider>-<variant>`
- Include comprehensive `values.yaml` with schema annotations
- Provide detailed documentation in provider-specific guides

### Contributing

1. Fork this repository
2. Create a feature branch
3. Add your enhancements
4. Test thoroughly
5. Submit a pull request to the main k0rdent-oot repository

## Support

For issues and questions:

- Provider-specific issues: See individual provider documentation
- General k0rdent questions: [k0rdent Documentation](https://docs.k0rdent.io/)
- Chart issues: Open an issue in this repository

## License

This project follows the same licensing as the main k0rdent project.