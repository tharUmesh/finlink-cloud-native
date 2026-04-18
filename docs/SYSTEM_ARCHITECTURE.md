# 1. High-Level Architecture Overview

FinLink follows a cloud-native microservices + event-driven architecture on Azure.

**Key principles demonstrated:**
- **Scalability:** ACA revision and replica auto-scaling based on HTTP/concurrency/CPU
- **High Availability:** Managed Container Apps Environment + replicated services + data failover
- **Sync + Async communication:** Azure API Management (sync) + Azure Service Bus (async)
- **Security:** Zero-trust with Entra ID, Key Vault, encryption
- **Extensibility:** Loose-coupled events (add new services without downtime)
- **Polyglot persistence:** PostgreSQL + Cosmos DB
- **DevOps:** Terraform + GitHub Actions

## Architecture Diagram

![FinLink System Architecture](azure_mobile_app_architecture_v2.png)

Temporary architecture text (until ACA diagram image is updated):

- Mobile App (React Native)
- Azure API Management (API Gateway)
- Azure Container Apps Environment (single managed environment)
- User App, Transaction App, Fraud App, Loan App, Notification App, Admin App
- Async events via Azure Service Bus: Fraud check -> Notification -> other workflows

Databases and platform services:
- Azure Database for PostgreSQL
- Azure Cosmos DB
- Azure Service Bus
- Azure Key Vault
- Azure Container Registry (ACR)

---

# 2. Detailed Component Breakdown (Azure Services)

| **Component**       | **Azure Service**                                 | **Tech Stack**                    | **Responsibility & Why It Fits Assignment**                                      |
|---------------------|---------------------------------------------------|-----------------------------------|----------------------------------------------------------------------------------|
| Mobile Frontend     | N/A (client)                                      | React Native + Expo               | User-facing wallet, transfers, loans. Mobile-first = realistic. Calls APIs only.  |
| API Gateway         | Azure API Management                              | REST + GraphQL                    | Single entry point, rate limiting, JWT validation, versioning. Sync comms.        |
| Microservices       | Azure Container Apps (ACA)                        | Node.js + Express/Docker          | 6 independent container apps in one managed ACA environment with auto-scaling.     |
| Auth                | Microsoft Entra ID (B2C)                          | JWT + MFA                         | Zero-trust auth for all users/admins.                                             |
| Async Messaging     | Azure Service Bus                                 | Queues & Topics                   | Fraud detection, notifications, loan processing. Demonstrates async clearly.      |
| Databases           | PostgreSQL Flexible Server + Cosmos DB            | SQL + NoSQL                       | Polyglot: relational for money + NoSQL for scale.                                 |
| AI Fraud            | Fraud App in ACA + Python model                   | Node.js + Python model            | Real-time scoring on every transaction before final settlement.                    |
| Container Registry  | Azure Container Registry (ACR)                    | Docker image registry             | Stores versioned service images deployed to ACA apps.                              |
| Secrets             | Azure Key Vault                                   | Managed Identity                  | Encryption at rest/transit.                                                       |
| Monitoring          | Azure Monitor + App Insights                      | Grafana optional                  | Dashboard in video demo.                                                          |

---

# 3. Communication Methods

- **Synchronous:** Mobile → API Management → ACA app endpoint (REST/GraphQL). Example: User clicks “Transfer”.
- **Asynchronous:** Transaction Service publishes event to Service Bus → Fraud Service consumes → decides approve/reject → Notification Service consumes. No blocking, resilient.

---

# 4. Sample Data Flows

**Example 1: P2P Transfer (sync + async)**
- User A → Mobile → API Mgmt → Transaction Service (sync).
- Transaction Service writes to PostgreSQL + publishes event to Service Bus.
- Fraud Service (async) runs ML check → if OK, update wallet in Cosmos DB.
- Notification Service sends push/email (simulated).

**Example 2: Micro-Loan Application**
- User applies (sync).
- Loan Service calls simple AI model.
- Async approval flow via Service Bus.

**Example 3: Scaling Demo**
- Simulate 1,000 concurrent transfers → ACA scales app replicas automatically.

---

# 5. Security Architecture

- Entra ID B2C for auth + MFA.
- All traffic over HTTPS + WAF in API Management.
- Data encrypted at rest (PostgreSQL TDE + Cosmos DB).
- Managed Identity + RBAC (least privilege).
- Audit logs to Log Analytics.
- Rate limiting & IP restrictions.

---

# 6. Scalability & High Availability

- Azure Container Apps Environment with automatic scale rules.
- Scale on HTTP load, concurrency, and resource usage.
- Cosmos DB auto-scale throughput.
- PostgreSQL read replicas + geo-replication.
- Circuit breakers and retries in Node services.

---

# 7. Deployment & DevOps

- Infrastructure as Code: Terraform (AzureRM provider).
- CI/CD: GitHub Actions → build Docker images → push to ACR → deploy to ACA.
- One-command deploy: terraform apply, then container app deployment/update.
- Blue-green or canary for zero-downtime feature addition.
