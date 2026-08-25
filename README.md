# Tech Challenge — Infrastructure as Code with Terraform and Ansible

## Overview

This project demonstrates a complete infrastructure-as-code and configuration management pipeline on AWS using Terraform and Ansible. The goal is to provision and configure a live web server entirely from code — no manual clicking in the AWS Console.

Terraform declares and provisions all cloud infrastructure. Ansible connects to the provisioned server over SSH and configures it automatically. The end result is a live Nginx web server running on an AWS EC2 instance, serving a Hello World page at the public IP address.

**Live URL:** http://98.86.182.47

---

## What We Did

### Phase 1 — Environment Setup

Installed and verified three tools using Homebrew: Terraform (upgraded to v1.15.4), the AWS CLI, and Ansible. Configured AWS credentials for a dedicated IAM user (`devops-3`) instead of root to avoid permission issues. Scaffolded the project with separate `terraform/` and `ansible/` directories to keep infrastructure provisioning and configuration management code cleanly separated.

### Phase 2 — Terraform

Wrote seven `.tf` files inside `terraform/`, each with a single responsibility:

- `main.tf` — AWS and random provider configuration
- `variables.tf` — input variables: region, instance type, project name, key pair
- `ec2.tf` — EC2 instance using the latest Amazon Linux 2 AMI data source
- `sg.tf` — security group with ports 22 (SSH) and 80 (HTTP) open
- `iam.tf` — IAM role with EC2 trust policy and instance profile
- `s3.tf` — S3 bucket with versioning enabled and random suffix for unique naming
- `output.tf` — exposes `ec2_public_ip` and `s3_bucket_name` after apply

Ran `terraform init` → `terraform plan` → `terraform apply` to provision all resources. The EC2 public IP (`98.86.182.47`) was surfaced as a Terraform output and used as the Ansible target in the next phase.

**Resources provisioned:**
- EC2 instance: t3.small, Amazon Linux 2, us-east-1
- S3 bucket: `devops-code-challenge3-bucket-43adf431`
- IAM role and instance profile
- Security group: ports 22 and 80

### Phase 3 — Ansible

Created two files in `ansible/`:

**`inventory.ini`** — points Ansible at the EC2 instance using the public IP from the Terraform output, the `ec2-user` SSH user, the downloaded key pair, and Python 3.8 as the interpreter (required for compatibility with Amazon Linux 2).

**`playbook.yml`** — four tasks running in order with `become: yes` (sudo):
1. Enable Nginx via `amazon-linux-extras` (required on Amazon Linux 2 before yum can find nginx)
2. Install Nginx using the `yum` module
3. Start and enable Nginx using the `service` module
4. Deploy the Hello World HTML page using the `copy` module to `/usr/share/nginx/html/index.html`

Verified connectivity with `ansible -m ping` before running the full playbook. All four tasks completed with `changed=4, failed=0`.

### Phase 4 — Verification

Confirmed the Hello World page loads in a browser at `http://98.86.182.47` and verified the HTML response via `curl`. Committed all files to this repository.

---

## Project Structure

```
devops-code-challenge3/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── ec2.tf
│   ├── sg.tf
│   ├── iam.tf
│   ├── s3.tf
│   └── output.tf
├── ansible/
│   ├── inventory.ini
│   └── playbook.yml
├── .gitignore
└── README.md
```

---

## How to Reproduce

### Prerequisites

- Terraform installed (`brew install terraform`)
- AWS CLI installed and configured (`aws configure`)
- Ansible installed (`pip3 install ansible==8.7.0`)
- An AWS key pair downloaded to `~/.ssh/devops-3-key.pem`

### Step 1 — Provision infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Note the `ec2_public_ip` output value.

### Step 2 — Update the inventory

Edit `ansible/inventory.ini` and replace the IP address with the `ec2_public_ip` from the Terraform output if reprovisioning.

### Step 3 — Install Python 3.8 on the EC2 instance

```bash
ansible -i ansible/inventory.ini webservers -m raw -a "sudo amazon-linux-extras install python3.8 -y"
```

### Step 4 — Test connectivity

```bash
ansible -i ansible/inventory.ini webservers -m ping
```

Expected: `SUCCESS => { "ping": "pong" }`

### Step 5 — Run the playbook

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

Expected: `ok=5, changed=4, failed=0`

### Step 6 — Verify

Open `http://<ec2_public_ip>` in a browser. The Hello, World! page should load.

---

## Errors Encountered and Fixed

| # | Error | Cause | Fix |
|---|-------|-------|-----|
| 1 | t2.micro not free tier eligible | AWS account no longer eligible for t2.micro free tier | Changed `instance_type` default in `variables.tf` to `t3.small` |
| 2 | Host key verification failed | SSH had never connected to the new EC2 instance | Ran `ssh-keyscan -H <ip> >> ~/.ssh/known_hosts` |
| 3 | SyntaxError: positional-only parameter syntax | Homebrew Ansible 2.20 requires Python 3.9+ on the managed node; Amazon Linux 2 only has Python 3.7 by default | Installed Python 3.8 via `amazon-linux-extras`; set `ansible_python_interpreter=/usr/bin/python3.8` in inventory |
| 4 | Ansible requires Python 3.9 or newer | Ansible 2.20 (Homebrew) still rejected Python 3.8 | Uninstalled Homebrew Ansible; used pip-installed Ansible 8.7.0 which only requires Python 3.7+ on managed nodes |
| 5 | No package matching 'nginx' found | Nginx is not in the default yum repos on Amazon Linux 2 | Added `amazon-linux-extras enable nginx1` task to playbook before the yum install |
| 6 | Large file blocked git push | `.terraform/` provider binaries exceeded GitHub's 100 MB file size limit | Added `.gitignore` to exclude `.terraform/`; used `git filter-branch` to remove from history |

---

## Submission Details

| Field | Value |
|-------|-------|
| GitHub Repository | https://github.com/cwhitaker777/IaC-w-Terraform-and-Ansible |
| Live URL | http://98.86.182.47 |
| EC2 Public IP | 98.86.182.47 |
| Instance Type | t3.small — Amazon Linux 2 |
| AWS IAM User | devops-3 |
| AWS Region | us-east-1 |
| Web Server | Nginx |
| S3 Bucket | devops-code-challenge3-bucket-43adf431 |
