# ☁️ GCP Class 7.5 Homework week by week 📝

## Week 1

<details>
    <summary>Wk1 Instructions</summary>

Follow the instructor's guidance for how to make a homepage with a VM.

If you use GCP CLI then: gcloud init
You need to select default Region and project.

Show your work:

1. Browser proof
   Open: http://<EXTERNAL_IP>/

2. at the end of the lesson, SSH into your VM and curl it

```bash
curl localhost
```

```bash
curl -s localhost | head
```

3. Service Proof
    > systemctl status nginx --no-pager

✨ Bonus: For the fearless who want some head.

If you want the page to refresh every 10 seconds (extra dopamine):

Add this inside <head>:

<meta http-equiv="refresh" content="10">

> If you use supera.sh then....

1. Machine proof

```bash
curl -s localhost/healthz
```

2. Engineer proof

```bash
curl -s localhost/metadata | jq .
```

### SEIR-I Lab 1 Gate Philosophy

Real engineers never say: --> “It works on my screen.”

They prove:
The service is reachable
The health endpoint works
The metadata endpoint returns valid JSON
The deployed infrastructure identifies itself

So the gate script checks exactly those things.

Lab 1 Gate Script
Find it here: --> https://github.com/BalericaAI/SEIR-1/blob/main/weekly_lessons/weeka/script/gate_gcp_vm_http_ok.sh

> NOTE!!!! You need to find the IP and change it!

Run it like this!

```bash
VM_IP=34.82.55.21 ./gate_gcp_vm_http_ok.sh
```

Remember, 34.82.55.21 is an example!! That's not your IP! You have to find your own IP! Don't ask the teach about this!!

Example output:

```json
Lab 1 Gate Result: PASS

PASS: Homepage reachable (HTTP 200)
PASS: /healthz endpoint returned 'ok'
PASS: /metadata returned valid JSON
PASS: metadata contains instance_name
PASS: metadata contains region
```

Files created:
gate_result.json
badge.txt

Example gate_result.json

```json
{
    "lab": "SEIR-I Lab 1",
    "target": "34.82.55.21",
    "status": "PASS",
    "details": [
        "PASS: Homepage reachable (HTTP 200)",
        "PASS: /healthz endpoint returned 'ok'",
        "PASS: /metadata returned valid JSON"
    ],
    "failures": []
}
```

</details>

---

### Week 2

<details>
<summary>Wk2 Instructions</summary>

SEIR-I Lab 2 (GCP Terraform) — Iowa VM + Startup Script + Port 80

**Goal:**

Students will deploy the Lab 1 VM stack via Terraform:

- Compute Engine VM
- Firewall rule to allow HTTP (port 80)
- Startup script installs nginx + serves the ops panel (/, /healthz, /metadata)
- Region/zone in Iowa (us-central1-a by default)

Workforce relevance

This is the real transition from “click ops” to “cloud engineer”:

- reproducible deployments
- version-controlled infrastructure
- predictable changes
- reviewable diff

1. Follow instructions for adding terraform files to a folder.
2. Add security .json file to the folder.
3. From the command line, do the following:

```bash
terraform init
```

```bash
terraform validate
```

```bash
terraform plan -out tfplan
```

```bash
terraform apply tfplan
```

```bash
terraform output vm_url
```

> Find the URL and open it in your browser.

All GAtes:
Find it, Run it: --> https://github.com/BalericaAI/SEIR-1/blob/main/weekly_lessons/weekb/python/gate_lab2_http.sh

CLI

```bash
VM_IP=$(terraform output -raw vm_external_ip)
VM_IP="$VM_IP" ./gate_lab2_http.sh
```

</details>

---
