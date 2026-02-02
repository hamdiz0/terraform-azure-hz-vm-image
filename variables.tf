variable "script_path" {
  type        = string
  description = "The path to the script that will be executed on the instance."
}

variable "public_ssh_key_path" {
  type        = string
  description = "The path to the public key that will be used for SSH access."
}

variable "private_ssh_key_path" {
  type        = string
  description = "The path to the private key that will be used for SSH access."
}

variable "base_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "The base image used to create the custom image (publisher, offer, sku, version)."
}

variable "custom_image_name" {
  type        = string
  default     = "custom_image"
  description = "The name of the custom image."
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "The VM size used to create the custom image."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the resources will be created and where the image will be stored."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "delete_resources" {
  type        = bool
  default     = true
  description = "If true, deletes VM, NIC, Public IP, NSG, VNet, and Subnet after image creation. Keeps only Resource Group and Image (note that this assumes that the Azure CLI is installed and configured)."
}
