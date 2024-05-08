variable "resource_group" {
  type    = string
  default = "RG1"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "VM1_nic_name" {
  type    = string
  default = "VM1-nic"
}

variable "VM2_nic_name" {
  type    = string
  default = "VM2-nic"
}

variable "VM1_ip_name" {
  type    = string
  default = "VM1-ip"
}

variable "VM2_ip_name" {
  type    = string
  default = "VM2-ip"
}

variable "fw_ip_name" {
  type    = string
  default = "fwpip"
}

variable "VM1_name" {
  type    = string
  default = "VM1"
}

variable "VM2_name" {
  type    = string
  default = "VM2"
}

variable "VM1_size" {
  type    = string
  default = "Standard_B1s"
}

variable "VM2_size" {
  type    = string
  default = "Standard_B1s"
}

variable "VM1_user" {
  type = string
}

variable "VM2_user" {
  type = string
}

variable "SSH_pk" {
  type = string
}