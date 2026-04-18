# FinLink Cloud-Native

FinLink is an AI-powered inclusive digital payments and micro-lending platform designed as a cloud-native university project. It targets unbanked and underbanked users with a mobile-first wallet experience, real-time fraud detection, and event-driven microservices on Azure.

## Why This Project

- Solves a real problem: financial inclusion plus digital payment fraud prevention.
- Matches cloud-native rubric areas directly: scalability, high availability, security, sync/async communication, IaC, CI/CD.
- Strong portfolio value: fintech + cloud + AI + DevOps in one project.

## Project Scope (MVP)

- User registration and wallet creation
- Deposit and withdraw simulation (bank transfer / cash-in / cash-out)
- Instant P2P transfers and QR-based simulation
- Micro-loan application flow with simple credit scoring
- Real-time fraud checks for transactions
- Notifications and transaction history
- Admin dashboard for monitoring and compliance views

## Users

- Unbanked users: people with no bank account; they can keep funds in-wallet and transact digitally.
- Underbanked users: people with a bank account but limited access/usability; they can move funds between bank and wallet.
- Admin/compliance users: monitor suspicious activity, health metrics, and alerts.

## High-Level Architecture (Azure)

- Client: React Native + Expo mobile app
- API Layer: Azure API Management
- Compute: Azure Kubernetes Service (AKS) for Node.js microservices
- Async Messaging: Azure Service Bus (queues/topics)
- Data: PostgreSQL + Cosmos DB
- Security: Microsoft Entra ID (B2C), Key Vault, RBAC, encryption
- Observability: Azure Monitor + Application Insights + Log Analytics
- DevOps: Terraform + GitHub Actions

Architecture reference:
- Full details: `docs/SYSTEM_ARCHITECTURE.md`
- Diagram image: `docs/azure_microservices_architecture.png`

## Microservices

- `user-service`: authentication and wallet profile setup
- `transaction-service`: transfers and transaction recording
- `fraud-service`: real-time fraud analysis (rule/ML)
- `loan-service`: loan application and scoring
- `notification-service`: status updates and alerts
- `admin-service`: admin and compliance views

## Repository Structure

```text
finlink-cloud-native/
|- mobile-frontend/
|  |- README.md
|- services/
|  |- user-service/
|  |  |- Dockerfile
|  |- transaction-service/
|  |  |- Dockerfile
|  |- fraud-service/
|  |  |- Dockerfile
|  |- loan-service/
|  |  |- Dockerfile
|  |- notification-service/
|  |  |- Dockerfile
|  |- admin-service/
|     |- Dockerfile
|- infrastructure/
|  |- main.tf
|  |- aks.tf
|- datasets/
|  |- README.md
|- docs/
|  |- SYSTEM_ARCHITECTURE.md
|  |- azure_microservices_architecture.png
|  |- report.md
|- .github/
|  |- workflows/
|     |- README.md
|- README.md
```

## Team Roles

- Person 1: Mobile Frontend (React Native + Expo)
- Person 2: Backend microservices and APIs
- Person 3: DevOps/Cloud (Terraform, AKS, CI/CD, IAM/security)
- Person 4: AI/Fraud model, testing, and documentation support

## 8-Day Execution Plan

1. Day 1: Project setup, repo alignment, cloud account, base infrastructure, mobile shell.
2. Day 2: User service + wallet flow + schema setup.
3. Day 3: Transfer flow, transaction history, API integration baseline.
4. Day 4: Loan service + initial fraud logic.
5. Day 5: Async event flow with Service Bus + notifications.
6. Day 6: Security hardening, autoscaling demo, CI/CD.
7. Day 7: End-to-end testing, report and demo prep.
8. Day 8: Final integration, video, submission.

## Cost and Feasibility

- Target budget: zero out-of-pocket using student cloud credits.
- Preferred platform: Azure for Students.
- Fallback: run services locally with Docker for demos if cloud limits are reached.

## Datasets and Resources

- Fraud datasets: Kaggle credit card fraud datasets (for training/testing fraud checks)
- Lending datasets: Kaggle P2P lending datasets (for loan simulation)
- Architecture and implementation notes: `docs/SYSTEM_ARCHITECTURE.md`

## Azure Access Sharing (Recommended)

To avoid sharing passwords, use Azure RBAC:

1. One owner creates the Azure for Students subscription.
2. Add teammates via Subscription -> Access control (IAM) -> Add role assignment.
3. Assign `Contributor` role to each teammate account.
4. Teammates use their own Microsoft accounts to access the same subscription.

## Current Status

- Repository scaffold is created.
- Service folders and Dockerfiles are in place.
- Base Terraform files exist.
- System architecture document and diagram are available.
- Implementation of frontend, microservices, infra modules, and CI/CD is the next phase.

## Next Immediate Steps

1. Initialize Expo app code in `mobile-frontend`.
2. Add Express starter code to each service.
3. Implement Terraform modules for network, AKS, data services, and API Management.
4. Add first GitHub Actions workflow for build and lint.
5. Add sample dataset files and schema docs under `datasets`.
