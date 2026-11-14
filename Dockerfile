FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates git ffmpeg tini && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get purge -y --auto-remove gnupg && \
    rm -rf /var/lib/apt/lists/*

RUN node --version && npm --version

# Pin to hermes-agent HEAD at the last successful pre-crash Railway image
# (deployment f0af1296, 2026-07-03T16:29:54Z). Build logs have expired; this
# is origin/main at that timestamp (next upstream commit landed at 16:44Z).
# That tree requires Python <3.14 and ships Telegram via the messaging extra
# (lazy-installed at runtime on the old image). Install it at build time so
# the adapter is present on first boot and future rebuilds cannot drift.
ARG HERMES_AGENT_SHA=a6b9597d5fb92969d605a858d5f14536e805553a
RUN git init /tmp/hermes-agent && \
    cd /tmp/hermes-agent && \
    git remote add origin https://github.com/NousResearch/hermes-agent.git && \
    git fetch --depth 1 origin ${HERMES_AGENT_SHA} && \
    git checkout --detach FETCH_HEAD && \
    git rev-parse HEAD && \
    uv pip install --system --no-cache -e ".[all,messaging]" && \
    rm -rf /tmp/hermes-agent/.git

COPY requirements.txt /app/requirements.txt
RUN uv pip install --system --no-cache -r /app/requirements.txt

RUN mkdir -p /data/.hermes

COPY server.py /app/server.py
COPY templates/ /app/templates/
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV HOME=/data
ENV HERMES_HOME=/data/.hermes

ENTRYPOINT ["tini", "--"]
CMD ["/app/start.sh"]
