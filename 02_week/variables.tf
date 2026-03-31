variable "project_id" {
  description = "seir-netrunner"
  type        = string
}

variable "region" {
  #Chewbacca: Iowa. Corn. Clouds. Infrastructure.
  type    = string
  default = "us-central1"
}

variable "zone" {
  #Chewbacca: A single node awakens here.
  type    = string
  default = "us-central1-a"
}

variable "student_name" {
  #Chewbacca: Your deploy banner. Own your work.
  type    = string
  default = "Thomas Bell"
}

variable "vm_name" {
  type    = string
  default = "week2_lab"
}