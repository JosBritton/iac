variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "tsig_key" {
  type      = string
  sensitive = true
}

variable "ciuser" {
  type = string
}
