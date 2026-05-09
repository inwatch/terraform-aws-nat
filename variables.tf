variable "vpc_id" {
  description = "ID du VPC où déployer l'instance fck-nat"
  type        = string
}

variable "subnet_id" {
  description = "ID du subnet public pour l'instance NAT"
  type        = string
}

variable "private_route_table_ids" {
  description = "Liste des route tables privées à rediriger vers le NAT"
  type        = list(string)
}

variable "api_token" {
  description = "Token Bearer GateWatch fourni lors de l'activation"
  type        = string
  sensitive   = true
}

variable "api_url" {
  description = "URL de l'API GateWatch"
  type        = string
  default     = "https://app.gatewatch.dev"
}

variable "name" {
  description = "Préfixe pour les ressources créées"
  type        = string
  default     = "gatewatch"
}

variable "instance_type" {
  description = "Type d'instance EC2 (doit être ARM64 — t4g recommandé)"
  type        = string
  default     = "t4g.nano"
}

variable "releases_bucket" {
  description = "Bucket S3 contenant les binaires de l'agent GateWatch"
  type        = string
  default     = "gatewatch-agent-releases"
}

variable "agent_version" {
  description = "Version de l'agent GateWatch à installer (ex: 0.4.0)"
  type        = string
}
