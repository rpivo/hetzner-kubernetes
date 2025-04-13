# hetzner-kubernetes

## What?

An opinionated setup for Kubernetes (k3s), Argo CD, Prometheus, & Grafana on Hetzner Cloud.

## Why?

Despite being convenient, the big cloud providers can be prohibitively expensive. With some additional setup, running highly available workloads on Hetzner is a cost-efficient alternative.

You can run several services in Kubernetes on Hetzner at the same price as a single service in AWS Fargate or EKS. Even a small app on Fargate or EKS can cost over $100 a month. By migrating to Kubernetes on Hetzner Cloud, you can reasonably save nearly a $1000 per year on that small app while still providing a highly available service.

## How?

### The Stack

- **Hetzner Cloud**: a cloud provider with great service, ease of use, and cost efficient servers. One of the most popular "low-cost" cloud provider on the market.
- **Kubernetes** (k3s, via kube-hetzner): k3s is a lightweight Kubernetes distribution that requires less hardware resources and allows you to run a fully functional Kubernetes cluster on a single node (not what we're doing here, but still interesting)
- **Argo CD**: GitOps continuous delivery tool making Kubernetes deployment delightful
- **Prometheus**: metrics collection for monitoring
- **Grafana**: visualization for monitoring
- **Docker Hub**: one free-to-use private image repo is allowed per Docker account
- **Bitnami Sealed Secrets**: an easy way to manage Kubernetes secrets in Argo CD

### The Opinionated Approach

In setting up this opinionated approach, I optimized for:

- cost efficiency
- high availability

In doing so, tradeoffs inevitably need to be made.

## Defining High Availability

Claude (Anthropic) defines High Availability for Kubernetes like this:

> For Kubernetes specifically, high availability means:
>
> - Control plane redundancy (multiple master nodes)
> - Distributed state storage (usually via etcd clusters)
> - Worker node redundancy for hosting application workloads
> - Load balancing capabilities for both internal cluster components and external traffic
>
> The goal is to ensure that the system can continue to operate without significant service disruption even when components fail, scheduled maintenance occurs, or during unexpected peak loads.

<hr />

## Hetzner Infrastructure

Deploying this infrastructure will provision these resources in Hetzner:

- 5 servers (3 control plane nodes, 2 worker nodes)
- 1 load balancer
- 10 primary IPs
- 1 firewall
- 1 network
- 2 snapshots
