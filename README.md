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

### 4. Retrieve the base kube-hetzner Terraform file.

[Kube-Hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner) provides a way to easily bootstrap hardware resources and k3s (a lightweight Kubernetes Provider) on Hetzner.

For a more thorough walkthrough of this step, you should follow their documentation. Here is a simplified walkthrough that has worked for me.

Retrieve the kube-hetzner Terraform file and put it in your terraform/k3s directory:

`curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/kube.tf.example -o terraform/k3s/main.tf`

This will pull a Terraform module that defines the cloud resources for Hetzner, and it has lots and lots of helpful comments. If this is your first time setting this up, I highly recommend pulling this file and reading through all of the comments.

I've prepared a modified version of this file in this repo at **terraform/main.tf** with these modifications:

-

Below, I've outlined deploying the Hetzner resources in either of 2 ways: locally or through a GitHub workflow. The GitHub workflow approach is preferred and more repeatable, but is more complicated. If you want to get through this quickly, go with the first approach.

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

#### Retrieve the base packer file for the snapshots

`curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/packer-template/hcloud-microos-snapshots.pkr.hcl -o hcloud-microos-snapshots.pkr.hcl`
