FROM node:14.18-bullseye-slim as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
  git=1:2.30.2-1 \
  ca-certificates=20210119 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/app

# ensure that private packages are authenticated
RUN --mount=type=secret,id=GITHUB_TOKEN GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN); git config --global url."https://$GITHUB_TOKEN@github.com/".insteadOf "https://github.com/"

COPY package.json package.json

COPY yarn.lock yarn.lock

# containers ran as users, we do not know what user will be running
RUN mkdir /node_modules && chmod 777 /node_modules \
  && yarn install \
  --network-concurrency 1 \
  --frozen-lockfile \
  --modules-folder /node_modules \
  && yarn cache clean



FROM node:14.18-bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  jq=1.6-2.1 \
  git=1:2.30.2-1 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/app

RUN yarn global add license-checker@^25.0.1 eslint@^7.32.0

COPY --from=builder /node_modules /node_modules

ENV SKIP_PREFLIGHT_CHECK=true

# make yarn cli colourfull
ENV FORCE_COLOR=1

RUN mkdir -p /node_modules/.cache && chmod 777 /node_modules/.cache
