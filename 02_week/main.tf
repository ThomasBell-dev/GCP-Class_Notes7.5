# This code is compatible with Terraform 4.25.0 and versions that are backwards compatible to 4.25.0.
# For information about validating this Terraform code, see https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration

resource "google_compute_firewall" "netrunner_allow_http" {
  name    = "netrunner-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "week2-homework" {
  boot_disk {
    auto_delete = true
    device_name = "week2-homework"

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20260310"
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src           = "vm_add-tf"
    goog-ops-agent-policy = "v2-template-1-5-0"
  }

  machine_type = "e2-medium"

  metadata = {
    enable-osconfig = "TRUE"
    startup-script  = "#!/bin/bash\nset -euo pipefail\n\n#Chewbacca: The node awakens. And it will speak in HTML, plain text, and JSON.\n\n#Thanks for Aaron!\nsleep 5\napt update -y\napt install -y nginx curl jq\n\nMETADATA=\"http://metadata.google.internal/computeMetadata/v1\"\nHDR=\"Metadata-Flavor: Google\"\nmd() { curl -fsS -H \"$HDR\" \"$${METADATA}/$1\" || echo \"unknown\"; }\n\nINSTANCE_NAME=\"$(md instance/name)\"\nHOSTNAME=\"$(hostname)\"\nPROJECT_ID=\"$(md project/project-id)\"\nZONE_FULL=\"$(md instance/zone)\"                  # projects/<id>/zones/us-central1-a\nZONE=\"$${ZONE_FULL##*/}\"\nREGION=\"$${ZONE%-*}\"\nMACHINE_TYPE_FULL=\"$(md instance/machine-type)\"\nMACHINE_TYPE=\"$${MACHINE_TYPE_FULL##*/}\"\n\nINTERNAL_IP=\"$(md instance/network-interfaces/0/ip)\"\nEXTERNAL_IP=\"$(md instance/network-interfaces/0/access-configs/0/external-ip)\"\nVPC_FULL=\"$(md instance/network-interfaces/0/network)\"\nSUBNET_FULL=\"$(md instance/network-interfaces/0/subnetwork)\"\nVPC=\"$${VPC_FULL##*/}\"\nSUBNET=\"$${SUBNET_FULL##*/}\"\n\nSTART_TIME_UTC=\"$(date -u +\"%Y-%m-%dT%H:%M:%SZ\")\"\n\n# --- Student banner ---\n# Students set this when creating the VM by adding a metadata key:\n#   student_name = Darth Malgus Jr\nSTUDENT_NAME=\"$(md instance/attributes/student_name)\"\n[[ -z \"$STUDENT_NAME\" || \"$STUDENT_NAME\" == \"unknown\" ]] && STUDENT_NAME=\"Anonymous Padawan (temporarily)\"\n\n# --- Basic system stats ---\nUPTIME=\"$(uptime -p || true)\"\nLOADAVG=\"$(awk '{print $1\" \"$2\" \"$3}' /proc/loadavg 2>/dev/null || echo \"unknown\")\"\n\nMEM_TOTAL_MB=\"$(free -m | awk '/Mem:/ {print $2}')\"\nMEM_USED_MB=\"$(free -m | awk '/Mem:/ {print $3}')\"\nMEM_FREE_MB=\"$(free -m | awk '/Mem:/ {print $4}')\"\n\nDISK_LINE=\"$(df -h / | tail -n 1)\"\nDISK_SIZE=\"$(echo \"$DISK_LINE\" | awk '{print $2}')\"\nDISK_USED=\"$(echo \"$DISK_LINE\" | awk '{print $3}')\"\nDISK_AVAIL=\"$(echo \"$DISK_LINE\" | awk '{print $4}')\"\nDISK_USEP=\"$(echo \"$DISK_LINE\" | awk '{print $5}')\"\n\n# --- Nginx config: add endpoints /healthz and /metadata ---\ncat > /etc/nginx/sites-available/default <<'EOF'\nserver {\n    listen 80 default_server;\n    listen [::]:80 default_server;\n\n    root /var/www/html;\n    index index.html;\n\n    #Chewbacca: The homepage is for humans.\n    location = / {\n        try_files /index.html =404;\n    }\n\n    #Chewbacca: Health checks are for machines. Keep it boring.\n    location = /healthz {\n        default_type text/plain;\n        return 200 \"ok\\n\";\n    }\n\n    #Chewbacca: Metadata is for engineers and scripts.\n    location = /metadata {\n        default_type application/json;\n        try_files /metadata.json =404;\n    }\n}\nEOF\n\n# --- Write JSON endpoint file ---\ncat > /var/www/html/metadata.json <<EOF\n{\n  \"service\": \"seir-i-node\",\n  \"student_name\": \"$(echo \"$STUDENT_NAME\" | sed 's/\"/\\\\\"/g')\",\n  \"project_id\": \"$PROJECT_ID\",\n  \"instance_name\": \"$INSTANCE_NAME\",\n  \"hostname\": \"$HOSTNAME\",\n  \"region\": \"$REGION\",\n  \"zone\": \"$ZONE\",\n  \"machine_type\": \"$MACHINE_TYPE\",\n  \"network\": {\n    \"vpc\": \"$VPC\",\n    \"subnet\": \"$SUBNET\",\n    \"internal_ip\": \"$INTERNAL_IP\",\n    \"external_ip\": \"$EXTERNAL_IP\"\n  },\n  \"health\": {\n    \"uptime\": \"$UPTIME\",\n    \"load_avg\": \"$LOADAVG\",\n    \"ram_mb\": {\"used\": $MEM_USED_MB, \"free\": $MEM_FREE_MB, \"total\": $MEM_TOTAL_MB},\n    \"disk_root\": {\"size\": \"$DISK_SIZE\", \"used\": \"$DISK_USED\", \"avail\": \"$DISK_AVAIL\", \"use_pct\": \"$DISK_USEP\"}\n  },\n  \"startup_utc\": \"$START_TIME_UTC\"\n}\nEOF\n\n# --- Write the main HTML dashboard ---\ncat > /var/www/html/index.html <<EOF\n<!DOCTYPE html>\n<html>\n<head>\n  <meta charset=\"utf-8\"/>\n  <title>SEIR-I Ops Panel</title>\n  <meta http-equiv=\"refresh\" content=\"10\">\n  <style>\n    body { background:#0b0c10; color:#c5c6c7; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, \"Liberation Mono\", monospace; }\n    .wrap { max-width: 950px; margin: 40px auto; padding: 24px; }\n    h1 { color:#66fcf1; margin:0 0 8px 0; }\n    .sub { color:#45a29e; margin-bottom: 18px; }\n    .banner { border:1px solid #66fcf1; border-radius: 10px; padding: 10px 14px; margin-bottom: 14px; background: rgba(102,252,241,0.06); }\n    .grid { display:grid; grid-template-columns: 1fr 1fr; gap: 14px; }\n    .card { border:1px solid #45a29e; border-radius: 10px; padding: 14px 16px; background: rgba(255,255,255,0.03); }\n    .k { color:#66fcf1; }\n    .v { color:#ffffff; }\n    .footer { margin-top: 18px; color:#45a29e; font-size: 12px; }\n    a { color:#66fcf1; text-decoration:none; }\n    a:hover { text-decoration:underline; }\n  </style>\n</head>\n<body>\n  <div class=\"wrap\">\n    <h1>⚡ SEIR-I Ops Panel — Node Online ⚡</h1>\n    <div class=\"sub\">This is your proof-of-life: VM + startup automation + HTTP service.</div>\n\n    <div class=\"banner\">\n      <span class=\"k\">Deploy Banner:</span>\n      <span class=\"v\">$${STUDENT_NAME}</span>\n      <span class=\"k\"> | Startup UTC:</span>\n      <span class=\"v\">$${START_TIME_UTC}</span>\n      <span class=\"k\"> | Auto-refresh:</span>\n      <span class=\"v\">10s</span>\n    </div>\n\n    <div class=\"grid\">\n      <div class=\"card\">\n        <div class=\"k\">Identity</div>\n        <div><span class=\"k\">Project:</span> <span class=\"v\">$${PROJECT_ID}</span></div>\n        <div><span class=\"k\">Instance:</span> <span class=\"v\">$${INSTANCE_NAME}</span></div>\n        <div><span class=\"k\">Hostname:</span> <span class=\"v\">$${HOSTNAME}</span></div>\n        <div><span class=\"k\">Machine:</span> <span class=\"v\">$${MACHINE_TYPE}</span></div>\n      </div>\n\n      <div class=\"card\">\n        <div class=\"k\">Location</div>\n        <div><span class=\"k\">Region:</span> <span class=\"v\">$${REGION}</span></div>\n        <div><span class=\"k\">Zone:</span> <span class=\"v\">$${ZONE}</span></div>\n        <div><span class=\"k\">Uptime:</span> <span class=\"v\">$${UPTIME}</span></div>\n        <div><span class=\"k\">Load Avg:</span> <span class=\"v\">$${LOADAVG}</span></div>\n      </div>\n\n      <div class=\"card\">\n        <div class=\"k\">Network</div>\n        <div><span class=\"k\">VPC:</span> <span class=\"v\">$${VPC}</span></div>\n        <div><span class=\"k\">Subnet:</span> <span class=\"v\">$${SUBNET}</span></div>\n        <div><span class=\"k\">Internal IP:</span> <span class=\"v\">$${INTERNAL_IP}</span></div>\n        <div><span class=\"k\">External IP:</span> <span class=\"v\">$${EXTERNAL_IP}</span></div>\n      </div>\n\n      <div class=\"card\">\n        <div class=\"k\">System</div>\n        <div><span class=\"k\">RAM:</span> <span class=\"v\">$${MEM_USED_MB} used / $${MEM_FREE_MB} free / $${MEM_TOTAL_MB} total (MB)</span></div>\n        <div><span class=\"k\">Disk (/):</span> <span class=\"v\">$${DISK_USED} used / $${DISK_AVAIL} avail / $${DISK_SIZE} total ($${DISK_USEP})</span></div>\n        <div class=\"k\" style=\"margin-top:10px;\">Endpoints</div>\n        <div><a href=\"/healthz\">/healthz</a> (plain text)</div>\n        <div><a href=\"/metadata\">/metadata</a> (JSON)</div>\n      </div>\n    </div>\n\n    <div class=\"footer\">\n      #Chewbacca: Humans celebrate the dashboard. Machines trust /healthz. Engineers curl /metadata.\n    </div>\n  </div>\n</body>\n</html>\nEOF\n\nsystemctl enable nginx >/dev/null 2>&1 || true\nsystemctl restart nginx\n\n#Chewbacca: Proof in terminal too.\necho \"OK: SEIR-I node deployed.\"\necho \"Try:\"\necho \"  curl -s localhost/healthz\"\necho \"  curl -s localhost/metadata | jq .\""
  }

  name = "week2-homework"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/seir-netrunner/regions/us-central1/subnetworks/default"
  }

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "612853436093-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["http-web"]
  zone = var.zone
}

module "ops_agent_policy" {
  source          = "github.com/terraform-google-modules/terraform-google-cloud-operations/modules/ops-agent-policy"
  project         = var.project_id
  zone            = var.zone
  assignment_id   = "goog-ops-agent-v2-template-1-5-0-us-central1-a"
  agents_rule = {
    package_state = "installed"
    version = "latest"
  }
  instance_filter = {
    all = false
    inclusion_labels = [{
      labels = {
        goog-ops-agent-policy = "v2-template-1-5-0"
      }
    }]
  }
}
