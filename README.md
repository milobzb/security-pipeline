# Security Pipeline

A reusable GitHub Actions security pipeline that scans a repository for hardcoded
secrets and vulnerable Python dependencies on every push, aggregates the results
into a single report, and fails the build if anything is found.

Built to demonstrate a working secure software development lifecycle (secure
SDLC) pattern: automated, continuous, and wired directly into the repos it
protects rather than a one-off manual check.

![Security Pipeline](https://github.com/milobzb/security-pipeline/actions/workflows/security-scan.yml/badge.svg)

## What it does

On every push or pull request, the pipeline:

1. **Scans for hardcoded secrets** using [gitleaks](https://github.com/gitleaks/gitleaks) — API keys, tokens, credentials accidentally committed to source.
2. **Audits Python dependencies** using [pip-audit](https://github.com/pypa/pip-audit) against `requirements.txt`, flagging packages with known CVEs.
3. **Aggregates both results** into one markdown summary (shown directly in the GitHub Actions run) and uploads the full JSON reports as a downloadable artifact.
4. **Fails the build** if either check finds something, so issues are caught at push time instead of discovered later.

## Why a reusable workflow instead of a copy-pasted YAML block

This pipeline is designed to be called from other repos rather than duplicated
into each one:

```yaml
# .github/workflows/security.yml in a consuming repo
name: Security Pipeline

on:
  push:
    branches: [main]
  pull_request:

jobs:
  security:
    uses: milobzb/security-pipeline/.github/workflows/security-scan.yml@main
```

One place to fix bugs or add new checks, every consuming repo picks up the
update automatically on its next run. Currently wired into:

- [Orphaned Account Detector](https://github.com/milobzb/Orphaned-Account-Detector)
- [RBAC Policy Checker](https://github.com/milobzb/rbac-policy-checker)

## Architecture

```
security-pipeline/
├── .github/workflows/
│   └── security-scan.yml   # the reusable workflow (workflow_call)
├── scripts/
│   ├── scan-secrets.sh      # installs + runs gitleaks, emits JSON
│   ├── scan-deps.sh         # installs + runs pip-audit, emits JSON
│   └── aggregate-report.sh  # merges both reports, sets pass/fail
├── Dockerfile               # same scan environment, runnable locally
└── README.md
```

The scan logic lives in standalone bash scripts rather than inline in the
workflow YAML, so it can be run identically in CI, in a container, or by hand
on a laptop — and so it shows up as real, standalone shell code rather than
being buried in a YAML string.

## Running it locally with Docker

```bash
docker build -t security-pipeline .
docker run --rm -v "$(pwd):/scan" security-pipeline \
  -c "/opt/security-pipeline/scripts/scan-secrets.sh /scan/security-reports && \
      /opt/security-pipeline/scripts/scan-deps.sh /scan/security-reports && \
      /opt/security-pipeline/scripts/aggregate-report.sh /scan/security-reports"
```

## Tech stack

Bash, YAML (GitHub Actions), Docker, gitleaks, pip-audit, jq.

## Author

Emanuel Botros — [emanuelbotros.com](https://emanuelbotros.com) · [LinkedIn](https://linkedin.com/in/milobzb)
