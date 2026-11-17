# Design decisions

Short notes on why the environment is built the way it is.

## 1. Managed identity instead of a password

**Choice:** the web app has a system-assigned managed identity and uses that to
read from Key Vault.

**Why:** a password or client secret has to be stored somewhere, can leak and
must be rotated. A managed identity is created and rotated by Azure, and it
disappears together with the app.

**Trade-off:** a system-assigned identity is tied to one resource. When several
apps need the same access, a user-assigned identity is easier to manage.

## 2. The secret value is not in Terraform

**Choice:** Terraform creates the vault and the *reference* to the secret, but
not the secret value. The value is set separately with the Azure CLI.

**Why:** everything Terraform manages ends up in the state file in plain text.
Keeping the value out of Terraform means it is also out of the state, the plan
output and the pipeline logs.

**Trade-off:** one manual step after the first deployment. In a real team this
step would be done by the application's own release process or a secret
rotation job.

## 3. Private endpoint for Key Vault

**Choice:** the vault's public endpoint is off. The web app reaches it through
a private endpoint and a private DNS zone.

**Why:** even with a stolen token, an attacker on the internet cannot reach the
vault. Access needs both the right identity *and* the right network.

**Trade-off:** setting the secret from a laptop needs a temporary firewall
exception (`key_vault_allowed_ips`). In a company network this would go
through a VPN, a jump host or a self-hosted pipeline agent inside the VNet.

## 4. Azure RBAC instead of access policies

**Choice:** `rbac_authorization_enabled = true`, with role assignments.

**Why:** one permission model for all Azure resources, permissions can be
granted per secret if needed, and every assignment is visible in one place.
The web app only gets `Key Vault Secrets User` (read). People who manage
secrets get `Key Vault Secrets Officer` through a separate variable.

## 5. Network security groups on both subnets

**Choice:** the private endpoint subnet only accepts port 443 from the app
subnet. The app subnet accepts no inbound traffic at all.

**Why:** by default every resource in a VNet can talk to every other resource.
Explicit rules limit how far an attacker can move if one component is
compromised.

## 6. Modules

**Choice:** four small modules (network, monitoring, keyvault, webapp) and a
root module that connects them.

**Why:** each module has one job, a clear set of inputs and outputs, and can be
reused or tested on its own. The role assignment between the web app and the
vault lives in the root module, because it belongs to neither of them: it is
the connection between the two.

## 7. Remote state with Entra ID authentication

**Choice:** state in Azure Blob Storage, with `use_azuread_auth = true`.

**Why:** the state is shared, locked during changes and versioned. Using Entra
ID instead of storage account keys means access to the state is personal and
can be revoked per user.

**Trade-off:** the state storage account is created by a script, not by
Terraform. Terraform cannot keep its state in something it still has to create.

## 8. OIDC in the pipeline

**Choice:** GitHub Actions logs in to Azure with OpenID Connect.

**Why:** there is no client secret stored in GitHub that could leak or expire.
Azure trusts a short-lived token that GitHub issues only for this repository.

## 9. Tests with a mocked provider

**Choice:** `terraform test` in plan mode against a mocked `azurerm` provider.

**Why:** the security baseline (HTTPS only, TLS 1.2, private vault, read-only
role) is checked on every commit, in seconds, without an Azure subscription or
any cost. If someone weakens a setting, the pipeline fails.

**Limit:** these tests check the configuration, not the running environment.
They do not prove that the app can actually read the secret after deployment.

## 10. Accepted scanner findings

Checkov runs in the pipeline. Findings were either fixed or accepted with a
reason written next to the resource (`#checkov:skip=...`):

| Finding | Decision |
| --- | --- |
| No NSG on the app subnet | Fixed: NSG added |
| HTTP logging, error messages, request tracing, health check | Fixed: enabled |
| Plan is not zone redundant / not a production SKU / single instance | Accepted: cost choice for a lab |
| Web app is publicly reachable, no login, no client certificate | Accepted: it is a public website |
| Key Vault public access is an expression | Accepted: off by default, only on for allow-listed IPs |

## What would change for production

- Premium App Service plan, at least two instances across availability zones.
- A Web Application Firewall (Front Door or Application Gateway) in front of
  the app, and the app itself no longer directly reachable.
- Separate state and separate subscriptions per environment.
- Alerts on failed requests and on unexpected Key Vault access.
- Pipeline agents inside the network, so the Key Vault firewall never has to
  open for an IP address.
