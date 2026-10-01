@export()
@sealed()
type mdfcSubPlansType = {
  StorageAccounts: 'DefenderForStorageV2'
  SqlServers: string?
  VirtualMachines: 'P1' | 'P2'
  Arm: 'PerApiCall' | 'PerSubscription'
  KeyVaults: 'PerTransaction' | 'PerKeyVault'
}
