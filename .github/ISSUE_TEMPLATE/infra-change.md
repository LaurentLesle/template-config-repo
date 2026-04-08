---
name: Infrastructure Change
about: Request or propose an infrastructure configuration change
labels: infrastructure
---

## Environment

- [ ] dev
- [ ] prod

## Change Description

<!-- What resources are being added, changed, or removed? -->

## Configuration Changes

<!-- Which config file(s) are affected? -->
- `configurations/env-???/config.yaml`

## Checklist

- [ ] Config YAML is valid
- [ ] State key follows naming convention (`<org>/<env>/<region>/<workload>/terraform.tfstate`)
- [ ] Tested plan locally (if possible)
- [ ] No secrets or sensitive values in config
