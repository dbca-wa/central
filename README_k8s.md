# Deployment with Kubernetes

Note: this deployment pathway is a community-contributed work in progress.
Eventually this deployment could be merged into upstream, and these docs could to the official docs.

## Maintain K8s deployment
### GitHub Actions build and push containers
The four Dockerfiles are built through GitHub Actions and pushed to a GitHub Packages repository.
This is DBCA's fork, so we use [DBCA's repo](https://github.com/orgs/dbca-wa/packages).
ODK Central would push to their own [getodk repo](https://github.com/orgs/getodk/packages).

The containers are re-built here only when upstream changes are merged.

### Let docker-compose use pre-built containers
An alternative `odkcentral.yml` links to the pre-built images.
The original `docker-compose.yml` still builds images locally.

### Translate compose to k8s
Install [kompose](https://kompose.io/) as per [instructions](https://github.com/kubernetes/kompose), then run

```
cd k8s
kompose convert -c -f odkcentral.yaml
```

This generates a helm chart with all of its YAML templates in the folder `/odkcentral`.
`kompose` defaults unspecified volume allocations to `100Mi`. Change the following volume allocations:
* TODO

### Deploy k8s stack
Follow the official [kompose docs](https://kompose.io/getting-started/) to deploy to Kubernetes with

```
cd odkcentral
kompose up
```

or deploy to Rancher:

* [Install Rancher](https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/quickstart-manual-setup/)
* Import the YAML files from the `k8s` folder in the correct order: volume claims, then dependencies (redis, secrets, mail, enketo), then service and nginx.
* Mount a configmap to override service config (e.g. custom db, custom mail server, custom sentry.io) - details TBA
