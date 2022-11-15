variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "key_name" {
  type = string
}

variable "num_of_instance" {
  type = number
  default = 1
}

variable "tag" {
  type = string
  default = "Web Server of Phonebook App"
}

variable "server-name" {
  type = string
  default = "project-instance"
}

variable "project-instance-ports" {
  type = list(number)
  description = "project-instance-sec-gr-inbound-rules"
  default = [22, 80, 8080]
}