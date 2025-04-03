# Hub-and-spoke Research Enclave

A Hub-and-Spoke Azure enclave for secure research.

## Purpose

To accelerate the deployment of a hub-and-spoke architecture for building secure research enclaves in Azure.

## Architecture

[Visio Diagram](/docs/architecture/Research%20Enclave%20Hub%20and%20Spoke%20diagrams.vsdx)

## Features

- Optional use of customer-managed keys for encryption at rest (required for FedRAMP Moderate compliance).
- Optional peering to a central hub.
- Choice between Active Directory or Entra ID for device authentication and management. Optionally, use Intune for device management with Entra ID.

### Compliance

The goal of the project is that the templates will deploy resources that are compliant with the following frameworks (according to the Azure Commercial built-in initiatives):

- HITRUST/HIPAA
- NIST 800-171 R2
- FedRAMP Moderate

Compliance with all the above frameworks is a work-in-progress.

## Deployment

Deployment documentation is found in the [Wiki](/../../wiki/Deployment).

## Alternative research enclave accelerators

- Azure TRE: <https://microsoft.github.io/AzureTRE/>
- Standalone Azure Secure Enclave for Research: <https://github.com/microsoft/Azure-Secure-Enclave-for-Research>
