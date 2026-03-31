provider "google" {
  #Chewbacca: The Force needs coordinates.
  project = var.project_id
  region  = var.region
  credentials = "netrunner.json"
  zone = var.zone
}

