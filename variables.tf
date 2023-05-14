variable "region" {
  default = "us-east-2"
}

variable "ami" {
  default = "ami-08333bccc35d71140"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "lnx-key-pair"
}

variable "security_groups" {
  default = ["lnx-sg"]
}