# Portable environment for running the security-pipeline scan scripts locally,
# outside of GitHub Actions. Bakes in gitleaks + pip-audit so the same checks
# run identically on a laptop as they do in CI.

FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    jq \
    git \
    && rm -rf /var/lib/apt/lists/*

ARG GITLEAKS_VERSION=8.30.1
RUN curl -sSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" -o /tmp/gitleaks.tar.gz \
    && tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks \
    && chmod +x /usr/local/bin/gitleaks \
    && rm /tmp/gitleaks.tar.gz

RUN pip install --no-cache-dir pip-audit

COPY scripts/ /opt/security-pipeline/scripts/
RUN chmod +x /opt/security-pipeline/scripts/*.sh

WORKDIR /scan
ENTRYPOINT ["/bin/bash"]
