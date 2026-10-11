# Project Titan v2 Pro 🚀

**Author:** Mohammed Hassan Abbas  
**Project Name:** Enterprise-Grade AWS Cloud Architecture Automated with Terraform  

---

## 📌 Executive Summary
**Project Titan v2 Pro** is a high-availability, multi-tier AWS cloud infrastructure designed and built entirely from scratch using **Terraform (Infrastructure as Code)**. Engineered by **Mohammed Hassan Abbas**, this project eliminates pre-built modular wrappers to demonstrate pure, foundational mastery in AWS networking, security perimeter design, traffic load balancing, and fault-tolerant architecture.

---

## 🏗️ Architecture & Network Topology

```text
                               [ Internet Users ]
                                       │
                                       ▼
                       ┌──────────────────────────────┐
                       │  Application Load Balancer   │
                       │       (titan-pro-alb)        │
                       └──────────────┬───────────────┘
                                      │ (HTTP: 80)
                ┌─────────────────────┴─────────────────────┐
                ▼                                           ▼
   ┌──────────────────────────┐                ┌──────────────────────────┐
   │    Public Subnet 1a      │                │    Public Subnet 1b      │
   │   (Internet Gateway)     │                │   (Multi-AZ Redundancy)  │
   └────────────┬─────────────┘                └──────────────────────────┘
                │
                ▼
   ┌──────────────────────────┐
   │       NAT Gateway        │ (Elastic IP)
   └────────────┬─────────────┘
                │
                ▼
   ┌──────────────────────────────────────────────────────────────────────┐
   │                       Private Subnet (AZ-1)                          │
   │  ┌────────────────────────────────────────────────────────────────┐  │
   │  │                    EC2 Web Server (Apache)                     │  │
   │  │                    (titan-automated-server)                    │  │
   │  └────────────────────────────────────────────────────────────────┘  │
   └──────────────────────────────────────────────────────────────────────┘
🛠️ Infrastructure Breakdown & Engineering Justifications
1. Custom VPC & Subnet Segmentation
Custom VPC (10.0.0.0/16): Provides complete network isolation and strict administrative control over IP allocation, routing, and gateways.

Public Subnets: Deployed across multiple Availability Zones (AZs) to host public-facing entry points (Load Balancers & NAT Gateways).

Private Subnets: Isolated network layers hosting core application compute instances, completely shielded from direct public internet ingress.

2. Security Gateways & Egress Control
Internet Gateway (IGW): Attached to the VPC to enable inbound and outbound internet traffic for the Public Subnets.

NAT Gateway & Elastic IP: Placed within the Public Subnet to route outbound traffic for instances in the Private Subnet.

Engineering Rationale: Allows private EC2 instances to download system updates and packages without assigning public IP addresses or exposing them to incoming external threats.

3. Compute & Automated Provisioning
EC2 Linux Server (titan-automated-server): Launched inside the Private Subnet.

UserData Bootstrapping: Fully automated script to install, enable, and start the Apache Web Server upon instance launch without manual SSH intervention.

4. High Availability & Traffic Management
Application Load Balancer (titan-pro-alb): Positions as the single entry point in Public Subnets, handling external HTTP traffic on Port 80 and distributing load dynamically.

Target Group (titan-pro-tg) & Health Checks: Configured with active health checks to ensure traffic is only routed to healthy targets.

5. Least-Privilege Security Boundaries
ALB Security Group: Permits incoming HTTP traffic on Port 80 from anywhere (0.0.0.0/0).

EC2 Security Group: Strictly restricts inbound HTTP access on Port 80 exclusively to traffic originating from the ALB Security Group, eliminating direct public exposure.

👨‍💻 Author
Mohammed Hassan Abbas

Cloud & Infrastructure Engineer
