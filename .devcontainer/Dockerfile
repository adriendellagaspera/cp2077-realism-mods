FROM rust:1-bookworm

# redscript-cli, pinned to the same parser tag CI validates against. Bump this
# deliberately alongside the matrix in .github/workflows/ci.yml.
ARG REDSCRIPT_TAG=v1.0.0-preview.22
# No --locked: the parser is pinned by --tag; transitive dep versions don't
# affect parser behaviour, and some older locks reference yanked crates.
RUN cargo install --git https://github.com/jac3km4/redscript \
        --tag ${REDSCRIPT_TAG} redscript-cli

# Mirror the repo's local checks so the container is a one-stop dev shell.
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 python3-pip git \
 && pip3 install --break-system-packages --no-cache-dir pre-commit pyyaml \
 && rm -rf /var/lib/apt/lists/*
