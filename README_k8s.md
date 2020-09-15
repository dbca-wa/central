# Deployment with Kubernetes

Note: this deployment pathway is a community-contributed work in progress.
Eventually this deployment could be merged into upstream, and these docs could to the official docs.

## Maintain K8s deployment
### GitHub Actions build and push containers
The four Dockerfiles are built through GitHub Actions and pushed to a GitHub Packages repository.
This is DBCA's fork, so we use [DBCA's repo](https://github.com/orgs/dbca-wa/packages).
ODK Central would push to their own [getodk repo](https://github.com/orgs/getodk/packages).
An "Organization secret" named `CR_PAT` is defined at the GH org (https://github.com/orgs/dbca-wa/) and provides write access to that organization's GH packages repo.

The containers are re-built here only when upstream changes are merged.

### Let docker-compose use pre-built containers
An alternative `odkcentral.yml` links to the pre-built images.
The two Redis images are also built to hard-code the config files, replacing the need to link to the local copies of the [redis config files](https://github.com/dbca-wa/central/tree/master/files/enketo).

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

Note: See the [kompose conversion chart](https://github.com/kubernetes/kompose/blob/master/docs/conversion.md) - not all
features are supported. If any unsupported features are added to `docker-compose.yml`, we'll have to handle them here.

### Deploy k8s stack
Follow the official [kompose docs](https://kompose.io/getting-started/) to deploy to Kubernetes with

```
cd odkcentral
kompose up
```

or deploy to Rancher:

* [Install Rancher](https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/quickstart-manual-setup/), create a cluster and within that cluster a project.
* Decide on a namespace (e.g. `odk-k8s-prod`) and use this namespace for each step below.
* Import the YAML files from the `k8s` folder in the correct order into the chosen namespace:
  first volume claims, then dependencies (postgres, redis, secrets, mail, enketo), then service and nginx.
* Volume "secrets":
  * Edit, remove command (`./generate-secrets.sh`), add Console "interactive".
  * Crashes when running with command.
  * Connect to console, run `./generate-secrets.sh`.
  * There's gotta be a better way to run this container.
* Volume "enketo":
  * Config specifies the names of Redis containers with underscores, which are invalid for K8s. Change to dash before rebuilding Docker image.
* To use custom db, mail, or other settings for the backend ("service"), create a config map in the same namespace with key
  ` default.json` and value:

```
{
    "default": {
        "database": {
            "host": "DBHOST",
            "user": "DBUSER@DBHOST",
            "password": "DBPASS",
            "database": "DBNAME",
            "ssl": {"rejectUnauthorized": false}
        },
        "server": {
            "port": 8383
        },
        "email": {
            "serviceAccount": "no-reply-odk@DOMAIN",
            "transport": "smtp",
            "transportOpts": {"host": "SMTPSERVER", "port": 25}
        },
        "xlsform": {
            "host": "localhost",
            "port": 5000
        },
        "enketo": {
            "url": "enketo:8005/-",
            "apiKey": "ENKETO_API_KEY"
            },
        "env": {
            "domain": "odkc.dbca.wa.gov.au"
        },
        "external": {}
    },
    "test": {
        "database": {
            "host": "localhost",
            "user": "jubilant",
            "password": "jubilant",
            "database": "jubilant_test"
        },
        "email": {
            "serviceAccount": "no-reply@DOMAIN",
            "transport": "json",
            "transportOpts": { "newline": "unix" }
        }
    }
}

```

* For workload "service", mount a volume of type "Config Map" at mount point `/usr/odk/config` using above config map.
* For workload "mail", follow the official docs on [configuring DKIM](https://docs.getodk.org/central-install-digital-ocean/#configuring-dkim) to create an RSA keypair.
  Create a configmap with a key `domain.key` and the contents of rsa.private
  as value and map the configmap as volume at `/etc/exim4`.

### Update k8s stack
Once all volumes are created and all containers are up and running,
the containers can be updated by "redeploying" them. If linked to the ":latest" tag, Rancher will download the latest version of the image and restart the container.
Unless breaking changes are introduced, this should upgrade ODK Central with no downtime.
It is advisable to spin up an additional test deployment identical to the production deployment to verify each upgrade.
