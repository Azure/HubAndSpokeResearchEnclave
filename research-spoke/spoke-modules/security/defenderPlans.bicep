targetScope = 'subscription'

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

var subPlans = {
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
