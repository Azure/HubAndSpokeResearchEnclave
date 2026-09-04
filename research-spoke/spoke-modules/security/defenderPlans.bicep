targetScope = 'subscription'

import { mdfcSubPlansType } from '../../../shared-modules/types/mdfcSubPlans.bicep'

param pricingTier string = 'Standard'

param plansToEnable array = [
  'StorageAccounts'
  'SqlServers'
  'VirtualMachines'
  'Arm'
]

param plansToEnableIfCommercial array = (az.environment().name == 'AzureCloud')
  ? [
      'KeyVaults'
    ]
  : []

var actualPlansToEnable = concat(plansToEnable, plansToEnableIfCommercial)

// Legacy values for Arm: 'PerApiCAll' and KeyVaults: 'PerTransaction' are no longer valid.
// These are set as defaults to allow compatibility with older deployments. The default values will be removed in a future release.
// use the following values in new deployments:
// param mdfcSubPlans = {
//   StorageAccounts: 'DefenderForStorageV2'
//   SqlServers: null
//   VirtualMachines: 'P2'
//   Arm: 'PerSubscription'
//   KeyVaults: 'PerKeyVault'
// }
param subPlans mdfcSubPlansType = {
  StorageAccounts: 'DefenderForStorageV2'
  SqlServers: null
  VirtualMachines: 'P2'
  Arm: 'PerApiCall'
  KeyVaults: 'PerTransaction'
}

// Enable one plan at a time only, otherwise failures may occur
@batchSize(1)
resource defenderPlan 'Microsoft.Security/pricings@2022-03-01' = [
  for plan in actualPlansToEnable: {
    name: plan
    properties: {
      pricingTier: pricingTier
      subPlan: subPlans[plan]
    }
  }
]
