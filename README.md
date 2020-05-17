# Provisioning and deployment strategies

Exploring different options and strategies for provisioning, publising and deploying applications to cloud provider(s) such as Google, AWS and Azure, using common tooling and application definitions. 

A sample application is also provided, deployed with `helm` to the target Kubernetes cluster, as a bencmark, to compare different environments. 

## Provisioning a Kubernetes cluster
For each major cloud provider, we can create a functioning `Kubernetes` cluster (+ backing registry / storage) with these simple commands (they have been tested with Free Tier accounts on each cloud):
```
# Create, destroy or select a target cloud provider
# It will remember your last choice, default is `local`

./cloud/select < local | aws | azure | google >
./cloud/create [ local | aws | azure | google ]
./cloud/delete [ local | aws | azure | google ]

# Settings defined in `./config/<target>/cloud.env`
```

The CLI tooling used to provision and configure each of these cloud providers differ substantially. To overcome these differences, we use a combination of shell scripts and configuration files, defined per provider.

We focus on provisioning 3 types of cloud resources:
 - `Storage` - Maps a disk volume to a Pod in K8S, and test disk R/W speeds
 - `Registry` - Define a container registry where we can push release artifacts
 - `Kubernetes` - Create and configure fully operational cluster and link to `kubectl`

 

We also include a special cloud provider called `local`, that will use your local `docker-desktop` (if installed) as the target cluster, instead of creating new resources in a cloud. 

```
./cloud/select local  # Use docker for desktop...
```

### Target cloud providers

We chose to include all the major cloud providers, and used the offerings for each of them:

- `aws` - `EKS` cluster, `ECR` registry and a `EFS` filesystem volume
- `azure` - `AKS` cluster, `ACR` registry, `AzureDisk` for storage
- `google` - `GKE` cluster, `GCR` registry, `GCE` persisted disk

We also include a special provider to test and deploy locally:
- `local` - `docker-desktop`, mapped to disk volume `$PWD/data`


## Building, publishing and deploying the sample app

This repository includes a simple React `app` with a backing python `api` that we use to test the CI/CD pipeline steps. The app is packaged into a `helm` chart, and deployed to Kubernetes.

We include following sample pipeline steps to:
 - `./build` - container images (either locally or remote)
 - `./publish` - container images to the target registry
 - `./deploy` - a release to Kubernetes using `helm` packages
 - `./clean` - removes installed version(s) of the `helm` package

### Advanced deployment strategies

We include working examples of both `canary deployments` as well as `blue/green deployments`. 

This is used to illisstrate the main differences in these release strategies:
 - `blue` - Default: Deploys a stable release, exposed to your end users
 - `green` - Deploy a new version, but it's not visible to end users
 - `canary` - Some of your end users will see this version while it's deployed


```
# Deploy the sample application to the selected cluster
# Usage: 
#   ./deploy [ <target> ] [ <publish> ]
# Where:
# - <target> is [ blue | green | canary ], defaults to 'blue'.
# - <publish> is [ true | false ], defaults to:
#   + blue => (exposed by default)
#   + green => (hidden by default)
#   + canary => (exposed by default)


# Use Case: Deploy blue/green side by side, then promote green
./deploy                # <-- deploy stable (blue) release
./deploy green true     # <-- promote new (green) release
./deploy blue false     # <-- demote current stable release


# Use Case: Create & test canary deployment, then remove it
./deploy                # <-- deploy stable (blue) release
./deploy canary         # <-- expose canary release to users
# ...at this point, canary release is visible...
./clean canary          # <-- Removes canary release

```
