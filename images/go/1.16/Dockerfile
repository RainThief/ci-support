FROM golang:1.16-buster as builder

RUN mkdir /gocache && chmod 777 /gocache

ENV GOCACHE=/gocache
ENV GOLANGCI_LINT_CACHE=/gocache

RUN apt-get update && apt-get install -y --no-install-recommends \
    xz-utils=5.2.4-1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# install golangci-lint
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.41.1 \
  # install nancy
  && curl -L "https://github.com/sonatype-nexus-community/nancy/releases/download/v1.0.22/nancy-v1.0.22-linux-amd64"  -o "nancy" \
  && chmod +x nancy \
  && mv nancy /usr/local/bin/nancy \
  # install go license checker
  && go get github.com/google/go-licenses

WORKDIR /usr/app



FROM golang:1.16-buster

ENV export GOPRIVATE=github.com/organisation/*
ENV CGO_ENABLED=1 GOOS=linux

RUN apt-get update && apt-get install -y --no-install-recommends \
    jq=1.5+dfsg-2+b1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV HOME=/home

RUN chmod 777 -R /go && chmod 777 /home

# ensure that private packages are authenticated
RUN --mount=type=secret,id=GITHUB_TOKEN GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN); git config --global url."https://$GITHUB_TOKEN@github.com/".insteadOf "https://github.com/"

WORKDIR /usr/app

COPY go.mod go.mod

COPY go.sum go.sum

RUN --mount=type=cache,target=/var/cache/go go mod download

COPY --from=builder /usr/local/bin/nancy /usr/local/bin/nancy
COPY --from=builder /go/bin/golangci-lint /go/bin/golangci-lint
COPY --from=builder /go/bin/go-licenses /go/bin/go-licenses
COPY --from=builder /go/pkg/mod/github.com/google/licenseclassifier* /go/pkg/mod/github.com/google/
