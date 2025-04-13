# hetzner-kubernetes

## What?

An opinionated setup for Kubernetes (k3s), Argo CD, Prometheus, & Grafana on Hetzner Cloud.

## Why?

Despite being convenient, the big cloud providers can be prohibitively expensive. With some additional setup, running highly available workloads on Hetzner is a cost-efficient alternative.

You can run several services in Kubernetes on Hetzner at the same price as a single service in AWS Fargate or EKS. Even a small app on Fargate or EKS can cost over $100 a month. By migrating to Kubernetes on Hetzner Cloud, you can reasonably save $1000 a year on that small app while still providing a highly available service.

<hr />

## Hetzner Infrastructure

Deploying this infrastructure will provision these resources in Hetzner:

- 5 servers (3 control plane nodes, 2 worker nodes)
- 1 load balancer
- 10 primary IPs
- 1 firewall
- 1 network
- 2 snapshots
