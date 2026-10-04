# AEGIS - DevSecOps pipeline and secure AWS infrastructure

Status: work in progress

A DevSecOps project: a containerized Python app, a security-gated CI pipeline, and AWS infrastructure written in Terraform.

## Pipeline (GitHub Actions)

Job 1, scan before build:
- Gitleaks: secrets in the full git history
- Trivy config: Terraform misconfigurations
- SonarCloud: static analysis of the Python code (quality gate)

Job 2, build then scan:
- Docker multi-stage build, non-root user
- Trivy image: blocks HIGH and CRITICAL CVEs

Every change goes through a branch and a pull request. A failed check blocks the merge.

## Infrastructure (Terraform)

- VPC with a public subnet (NAT gateway) and a private subnet for the container
- ECS Fargate in the private subnet, no inbound access, outbound HTTPS only
- ECR with immutable tags (commit SHA) and scan on push
- S3 bucket for security logs: public access blocked, encrypted with a KMS key (rotation on)
- CloudWatch Logs, IAM roles with least privilege

## Roadmap

- [x] Pipeline green: secrets, IaC, SAST and image scans
- [x] Fix all HIGH and CRITICAL Trivy findings
- [x] Terraform applied on a local AWS emulator (Floci)
- [ ] Run the container on ECS in the emulator
- [ ] Deploy on real AWS (Learner Lab)
- [ ] Automatic deploy step after merge
- [ ] CloudTrail, CloudWatch alarm to SNS

## Tools

GitHub Actions, Gitleaks, Trivy, SonarCloud, Docker, Terraform, AWS (VPC, ECS Fargate, ECR, S3, KMS, IAM, CloudWatch), Floci