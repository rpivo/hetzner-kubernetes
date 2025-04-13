# hetzner-kubernetes

- [What?](#what)
- [Why?](#why)
- [How?](#how)
- [Prerequisites](#prerequisites)
- [Walkthrough](#walkthrough)

## What?

An opinionated setup for Kubernetes (k3s), Argo CD, Prometheus, & Grafana on Hetzner Cloud.

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

- a Hetzner account
- a private Docker repo
- an application that is ready to serve and will accept GET requests (and optionally has a domain name)

<hr />

## Walkthrough
