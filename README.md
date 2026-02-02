# hz-ami-gen (Azure)

##### This module uses the `Terraform Provisioners` to execute a provided script from the inputs on an instance which is based on the specified `base image`.

##### The module requires an `ssh key pair` to be created both the private and public key paths must be provided in the inputs.

##### The script path also needs to be provided to create the new `custom image`.

##### The module creates all required resources (Resource Group, VNet, Subnet, Public IP, NIC, NSG) and can optionally delete them after image creation, keeping only the Resource Group and the Image.

#### Usage :
##### generate an ssh key pair :
```sh
mkdir key-pair ; cd key-pair
ssh-keygen -f ssh-key
```

##### deploy the module :
```hcl
module "custom-image" {
  source = "hamdiz0/hz-ami-gen/azure"

  public_ssh_key_path  = "./key-pair/ssh-key.pub"
  private_ssh_key_path = "./key-pair/ssh-key"
  script_path          = "./scripts/script.sh"

  resource_group_name = "custom_image_rg"
  location            = "italynorth"

  base_image = {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }

  custom_image_name = "custom_image_name"

  delete_resources = true
}
```

#### Note :
##### When `delete_resources` is set to `true`, the module will delete all resources except the Resource Group and the Image after the image creation. This requires the `Azure CLI` to be installed and configured.
