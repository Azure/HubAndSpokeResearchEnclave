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

param subPlans mdfcSubPlansType

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
