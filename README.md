# ☁️ Azure Enterprise DevOps Platform (IaC)

![Terraform](https://img.shields.io/badge/Terraform-1.9.0-purple?style=flat&logo=terraform)
![Azure](https://img.shields.io/badge/Azure-Production_Grade-blue?style=flat&logo=microsoftazure)
![Kubernetes](https://img.shields.io/badge/AKS-1.29-326ce5?style=flat&logo=kubernetes)
![CI/CD](https://img.shields.io/badge/GitHub_Actions-Self_Hosted-2088FF?style=flat&logo=github-actions)
![Security](https://img.shields.io/badge/DevSecOps-Trivy-green)

A comprehensive, **production-grade infrastructure lab** simulating a high-security environment (Fintech/Banking standards) on Microsoft Azure.

This project implements a **Zero Trust** architecture using **Terraform**, **Azure Kubernetes Service (AKS)**, and **GitHub Actions**, featuring private networking, TLS termination, and automated DevSecOps pipelines.

---

## 🏗️ Architecture Overview

The infrastructure is designed around a **Hub & Spoke** network topology (simulated via Global Peering) to ensure isolation and overcome regional capacity constraints.

```mermaid
graph TD
    User((Internet User)) -->|HTTPS/443| WAF[App Gateway WAF v2]
    
    subgraph "Region A: East US (Core)"
        WAF -->|Private VNet Traffic| AKS[AKS Cluster]
        AKS -->|Workload Identity| KV[Key Vault]
        AKS -->|Private Link| SQL[Azure SQL]
        
        subgraph "Private Network"
            ACR[Azure Container Registry]
            PE_ACR[Private Endpoint]
        end
    end
    
    subgraph "Region B: East US 2 (Ops)"
        Runner[Self-Hosted Runner VM]
    end
    
    %% Connections
    Runner <==>|Global VNet Peering| ACR
    GitHub[GitHub Actions Cloud] -.->|OIDC Control| Runner
    AKS -.->|Pull Image| ACR

🚀 Key Features
1. Infrastructure as Code (Terraform)

    Modular Design: Reusable local modules for aks, network, key-vault, app-gateway, etc.

    Multi-Environment Strategy:

        live/dev: Single node, cost-optimized active environment.

        live/uat: High Availability simulation (2 nodes, autoscaling) and infrastructure promotion.

    State Management: Remote backend on Azure Storage with state locking and OIDC authentication.

2. Zero Trust Networking & Security

    Private Connectivity:

        Azure Container Registry (ACR) is strictly private (Premium SKU). No public internet access allowed.

        Azure SQL Database accessed solely via Private Endpoints.

    WAF & TLS Termination: Application Gateway v2 (WAF) handles SSL offloading using certificates managed in Key Vault.

    Network Security Groups (NSGs): Granular traffic filtering. Only port 443 is exposed to the internet via the WAF.

    Identity:

        Workload Identity Federation: Pods authenticate to Key Vault without secrets (Service Accounts).

        Managed Identities: Used for all Azure resource interactions (AppGW -> KV, AKS -> ACR).

3. CI/CD & DevSecOps (GitHub Actions)

    Self-Hosted Runners: To bypass the private network restriction of the ACR, a Linux VM is provisioned dynamically in a secondary region (eastus2) and peered to the core network.

    Vulnerability Scanning: Trivy is integrated into the build pipeline. Images are scanned for Critical/High CVEs before being pushed to the registry.

    OIDC Authentication: No long-lived client secrets. GitHub authenticates to Azure via OpenID Connect.

🛠️ Technology Stack
Category	Technology	Usage
IaC	Terraform	Provisioning of all resources (Compute, Net, DB, IAM).
Compute	Azure AKS	Container orchestration with Azure CNI.
Networking	VNet Peering	Connecting Global Runners to Core resources.
Security	Key Vault	Certificate and Secret management with RBAC.
Ingress	App Gateway	Layer 7 Load Balancing + WAF (OWASP 3.2).
CI/CD	GitHub Actions	Automated Plans, Applies, and Docker Builds.
Database	Azure SQL	Relational data persistence with Private Link.
🔄 CI/CD Workflows
1. Infrastructure Pipeline (terraform-dev.yml)

    Pull Request: Triggers terraform plan. Validates syntax and shows changes.

    Merge to Main: Triggers terraform apply.

        Self-Healing: Automatically reprovisions the Self-Hosted Runner if configuration changes (e.g., updating cloud-init scripts).

2. Application Pipeline (build-hello-api-dev.yml)

    Runs on: Self-Hosted Runner (Private VNet).

    Steps:

        Build: Docker build locally.

        Audit: Run Trivy scan. Breaks build if vulnerabilities are found.

        Push: Push to Private ACR (over Azure Backbone).

        Deploy: kubectl rollout restart on AKS.

3. Environment Promotion (deploy-uat.yml)

    Strategy: Manual promotion.

    Action: Takes an existing, tested image tag from DEV and promotes it to the UAT cluster without rebuilding binaries ("Build Once, Deploy Many").

🧬 Highlight: Solving the Private Registry Challenge

One of the main challenges in this project was accessing a Private Azure Container Registry from GitHub Actions. Since GitHub-hosted runners are on the public internet, they cannot reach the private endpoint of the ACR.

The Solution:

    Provisioned a Virtual Machine in a secondary region (eastus2) to avoid capacity limits in eastus.

    Established Global VNet Peering between the Runner VNet and the Core VNet.

    Configured Private DNS Zones linked to both VNets.

    Registered the VM as a GitHub Self-Hosted Runner via Terraform user_data scripts.

Result: Secure, private image builds without exposing the registry to the internet.
📂 Repository Structure
Bash

.
├── .github/workflows      # CI/CD Pipelines
│   ├── build-hello-api-dev.yml  # DevSecOps Build & Deploy
│   ├── deploy-uat.yml           # Promotion to UAT (Manual)
│   ├── terraform-dev.yml        # IaC Automation (Plan/Apply)
│   └── terraform-uat.yml        # IaC Plan for UAT (Manual)
├── apps
│   └── hello-api          # Python Application Code & Dockerfile
├── k8s                    # Kubernetes Manifests (Secrets Provider)
├── live                   # Environment instantiations
│   ├── dev                # Development (Active environment)
│   │   ├── scripts        # Cloud-init (Runner Provisioning)
│   │   └── main.tf        # Infrastructure Entrypoint
│   ├── uat                # UAT (Pre-prod code-ready)
│   └── governance         # Azure Policy definitions
└── modules                # Reusable Terraform components
    ├── acr                # Azure Container Registry
    ├── aks                # Azure Kubernetes Service
    ├── app-gateway        # Application Gateway WAF v2
    ├── key-vault          # Key Management
    ├── network            # VNet & Subnets
    ├── nsg                # Network Security Groups
    ├── linux-vm           # Self-Hosted Runner Infrastructure
    ├── workload-identity  # OIDC Federation
    └── ...

👤 Author

Justino Boggio DevOps Engineer | Cloud Architect

LinkedIn | GitHub