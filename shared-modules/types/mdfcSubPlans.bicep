@export()
@sealed()
type mdfcSubPlansType = {
  StorageAccounts: 'DefenderForStorageV2'
  SqlServers: string?
  VirtualMachines: 'P2'
  Arm: 'PerApiCall' | 'PerSubscription'
  KeyVaults: 'PerTransaction' | 'PerKeyVault'
}
