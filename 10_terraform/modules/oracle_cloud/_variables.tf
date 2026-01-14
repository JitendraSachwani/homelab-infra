variable "compartment_id" {
  type = string
  default = "id"
}

variable "availability_domain" {
  type = string
  default = "1"
}

variable "instance_shape" {
  type    = string
  default = "VM.Standard.E2.1.Micro"
}
