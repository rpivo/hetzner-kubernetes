# hetzner-kubernetes

An opinionated setup for Kubernetes (k3s), Argo CD, Prometheus, & Grafana on Hetzner Cloud.

- [Why?](#why)
- [How?](#how)
- [Prerequisites](#prerequisites)
- [Walkthrough](#walkthrough)

## Why?

Despite being convenient, the big cloud providers can be prohibitively expensive. With some additional setup, running highly available workloads on Hetzner is a cost-efficient alternative.

You can run several services in Kubernetes on Hetzner at the same price as a single service in AWS Fargate or EKS. Even a small app on Fargate or EKS can cost over $100 a month. By migrating to Kubernetes on Hetzner Cloud, you can reasonably save nearly a $1000 per year on that small app while still providing a highly available service.

## How?

### Defining High Availability

Claude (Anthropic) defines High Availability for Kubernetes like this:

> For Kubernetes specifically, high availability means:
>
> - Control plane redundancy (multiple master nodes)
> - Distributed state storage (usually via etcd clusters)
> - Worker node redundancy for hosting application workloads
> - Load balancing capabilities for both internal cluster components and external traffic
>
> The goal is to ensure that the system can continue to operate without significant service disruption even when components fail, scheduled maintenance occurs, or during unexpected peak loads.

[The Rancher docs](https://ranchermanager.docs.rancher.com/reference-guides/kubernetes-concepts) define a control plane quorum like this:

> Although you can run etcd on just one node, etcd requires a majority of nodes, a quorum, to agree on updates to the cluster state. The cluster should always contain enough healthy etcd nodes to form a quorum. For a cluster with n members, a quorum is (n/2)+1. For any odd-sized cluster, adding one node will always increase the number of nodes necessary for a quorum.

> Three etcd nodes is generally sufficient for smaller clusters and five etcd nodes for large clusters.

### The Opinionated Approach

In setting up this opinionated approach, I optimized for:

- cost efficiency
- high availability

Focusing on the definition of High Availability above, I've set up this guide to create a Kubernetes cluster with:

- 3 control plane nodes. This is the minimum number of control plane nodes that allow for a quorum
- 2 worker nodes. While arguably risky for mission-critical production workloads, this passes as "highly available". If one node goes down, the other node will have your services still available, and Kubernetes will self-heal.

Tradeoffs inevitably needed to be made to curate this stack. After having tried many things, I've found this particular stack to be relatively easy to set up while also being reliable, well-maintained, and fun to use.

That being said, you may not want to do things exactly as I've done them here. This setup is pretty modular -- feel free to leave out parts or swap things out for other things that you like!

### The Stack

- **Hetzner Cloud**: a cloud provider with great service, ease of use, and cost efficient servers. One of the most popular low-cost cloud providers on the market.
- **Kubernetes** (k3s, via kube-hetzner): k3s is a lightweight Kubernetes distribution that requires less hardware resources and allows you to run a fully functional Kubernetes cluster on a single node (not what we're doing here, but still interesting)
- **Argo CD**: GitOps continuous delivery tool making Kubernetes deployment delightful
- **Prometheus**: metrics collection for monitoring
- **Grafana**: visualization for monitoring
- **Terraform**: industry standard for cloud-agnostic infra configuration
- **Docker Hub**: one free-to-use private image repo is allowed per Docker account
- **GitHub Workflows**: a delightful way to deploy Docker and Terraform resoures
- **Bitnami Sealed Secrets**: an easy way to manage Kubernetes secrets in Argo CD

This stack deploys these hardware resources in Hetzner:

- 5 servers (3 control plane nodes, 2 worker nodes)
- 1 load balancer
- 10 primary IPs
- 1 firewall
- 1 network
- 2 snapshots

Additionally a Kubernetes cluster is provisioned with:

- 3 control plane nodes
- 2 worker nodes
- Argo CD setup
- Prometheus setup, tracking a single metric just to validate it's working (with docs on scaling up)
- Grafana setup

## Prerequisites

This guide assumes you have:

- Terraform installed locally
- a Hetzner account
- a private Docker repo
- an application that is ready to serve and will accept GET requests (and optionally has a domain name)

<hr />

## Walkthrough

I'm writing this walkthrough as if you're working in a new repo, but this can be done in a "brown field" repo as well.

### 1. Create a .gitignore file to avoid checking in sensitive information

Here's an example gitignore to avoid checking in some of the files that we'll be working with throughout this walkthrough. This gitignore is also available in this repo.

```
.env
.env*.local
.terraform
.terraform.lock.hcl
*.key
*.key.pub
*.pkr.hcl
*.tfstate
*.tfstate.*
*.tfvars
kubeconfig.yaml
secrets/
```

### 2. Create an API Token in Hetzner

Create an API token in Hetzner with read-write permissions. You'll need the token shortly, so copy it. (And, of course, never commit it)

### 3. Create a terraform directory

We'll put our Terraform files in here.

```sh
mkdir -p terraform/k3s
```

### 4. Create the k3s Terraform File

```sh
touch terraform/k3s/main.tf
```

Add this content:

```tf
# Define a module named "kube-hetzner" which sets up a Kubernetes cluster on Hetzner Cloud
module "kube-hetzner" {
  # Specify which provider this module should use
  providers = {
    hcloud = hcloud
  }

  # Pass the Hetzner Cloud API token from a variable for authentication
  hcloud_token = var.hcloud_token
  # Specify the source of the module (from Terraform Registry)
  source = "kube-hetzner/kube-hetzner/hcloud"
  # Read the SSH public key from a file for node access
  ssh_public_key = file("./hetzner_ssh.key.pub")
  # Read the SSH private key from a file for node access
  ssh_private_key = file("./hetzner_ssh.key")
  # Set the network region for the cluster from one of: eu-central, us-east, us-west, ap-southeast
  network_region = "us-east"

  # Define the control plane nodes (master nodes that run the Kubernetes control plane)
  control_plane_nodepools = [
    {
      # Name for this group of control plane nodes
      name        = "control-plane",
      # Server type/size to use (cpx11 is currently the cheapest server type: 2 vCPUs, 4GB RAM)
      server_type = "cpx11",
      # Datacenter location. Choices:
      # DE Falkenstein fsn1, US Ashburn, VA ash, US Hillsboro, OR hil, SG Singapore sin, DE Nuremberg nbg1, FI Helsinki hel1
      location    = "ash",
      # No custom Kubernetes labels for these nodes
      labels      = [],
      # Add a taint to prefer workloads not schedule on control plane nodes
      taints      = ["node-role.kubernetes.io/control-plane=:PreferNoSchedule"],
      # Create 3 control plane nodes for high availability
      count       = 3
    }
  ]

  # Define the worker nodes (agent nodes that run application workloads)
  agent_nodepools = [
    {
      # Name for this group of worker nodes
      name        = "agent",
      # Same server type as control plane nodes
      server_type = "cpx11",
      # Same location as control plane nodes
      location    = "ash",
      # No custom Kubernetes labels for these nodes
      labels      = [],
      # No taints, so pods can be scheduled freely
      taints      = [],
      # Create 2 worker nodes
      count       = 2
    }
  ]

  # Specify the load balancer type for ingress traffic
  # "lb11" is currently the smallest, cheapest load balancer
  load_balancer_type     = "lb11"
  # Set the load balancer in same location as nodes
  load_balancer_location = "ash"
  # Drain nodes safely during system upgrades to prevent workload disruption
  system_upgrade_use_drain = true

  # Define DNS servers for cluster to use
  dns_servers = [
    "1.1.1.1",
    "8.8.8.8",
    "2606:4700:4700::1111",
  ]

  # Don't automatically create a kubeconfig file
  create_kubeconfig = false
  # Don't create Kustomization resources
  create_kustomization = false
}

# Configure the Hetzner Cloud provider
provider "hcloud" {
  # Use the Hetzner Cloud API token from a variable
  token = var.hcloud_token
}

# Specify Terraform and provider version requirements
terraform {
  # Require Terraform version 1.5.0 or newer. Change this to newer versions as need be.
  required_version = ">= 1.5.0"

  # Define required providers with version constraints
  required_providers {
    hcloud = {
      # Source of the Hetzner Cloud provider
      source  = "hetznercloud/hcloud"
      # Require version 1.49.1 or newer of the provider.  Change this to newer versions as need be.
      version = ">= 1.49.1"
    }
  }
}

# Define an output to access the kubeconfig after applying
output "kubeconfig" {
  # Get the kubeconfig from the module output
  value     = module.kube-hetzner.kubeconfig
  # Mark as sensitive to prevent showing in logs (contains credentials)
  sensitive = true
}

# Define the Hetzner Cloud API token variable
variable "hcloud_token" {
  # Mark as sensitive to prevent showing in logs
  sensitive = true
  # Default to empty string (should be provided externally)
  default   = ""
}
```

If you want a version of this file without comments, copy the contents of the file at terraform/k3s/main.tf in this repo.

This Terraform module has been adapted from the kube-hetzner project. [kube-hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner) provides a way to easily bootstrap hardware resources and k3s (a lightweight Kubernetes Provider) on Hetzner.

For a more thorough walkthrough of this step, you should follow their documentation. Here is a simplified walkthrough that has worked for me.

Retrieve the kube-hetzner Terraform file and put it in your terraform/k3s directory:

`curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/kube.tf.example -o terraform/k3s/main.tf`

This will pull a Terraform module that defines the cloud resources for Hetzner, and it has lots and lots of helpful comments. If this is your first time setting this up, I highly recommend pulling this file and reading through all of the comments.

### 5. Retrieve the Packer file for the OpenSUSE MicroOS Server snapshots

kube-hetzner provides snapshots for your servers to use.

```sh
curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/packer-template/hcloud-microos-snapshots.pkr.hcl -o terraform/k3s/hcloud-microos-snapshots.pkr.hcl
```

-

Below, I've outlined how to deploy the Hetzner resources in either of 2 ways: locally or through a GitHub workflow. The GitHub workflow approach is preferred and more repeatable, but is more complicated. If you want to get through this quickly, go with the first approach.

<hr />

#### Terraform Deployment: Option 1 - Deploy Locally

### 4a. Create a terraform.tfvars file that contains your hcloud token

```sh
touch terraform/terraform.tfvars
```

Add your Hetzner API token in there as `hcloud_token`:

```
hcloud_token = {{ your hetzner api token }}
```

<hr />

#### Terraform Deployment: Option 2 - Deploy with a GitHub Workflow

<hr />
