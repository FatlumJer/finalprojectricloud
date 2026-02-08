
data "azurerm_resource_group" "sandbox" {
  name = var.resource_group_name
}

module "network" {
  source              = "./modules/vnet"
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = data.azurerm_resource_group.sandbox.location
}

module "aks" {
  source              = "./modules/aks"
  cluster_name        = var.cluster_name
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = data.azurerm_resource_group.sandbox.location
  node_vm_size        = var.node_vm_size
  subnet_id           = module.network.subnet_id
}