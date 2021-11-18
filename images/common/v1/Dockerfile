FROM registry.access.redhat.com/ubi8/ubi-minimal:8.4 as builder

RUN microdnf install --nodocs \
  xz-5.2.4-3.el8.x86_64 \
  tar-2:1.30-5.el8.x86_64 \
  && microdnf clean all

# install hadolint (Dockerfile linter)
RUN curl -L "https://github.com/hadolint/hadolint/releases/download/v2.7.0/hadolint-Linux-x86_64"  -o "hadolint" \
  && chmod +x hadolint \
  && mv hadolint /usr/local/bin/hadolint

# install shellcheck (bash linter)
RUN curl -L "https://github.com/koalaman/shellcheck/releases/download/v0.7.2/shellcheck-v0.7.2.linux.x86_64.tar.xz"  -o "shellcheck.tar.xz" \
  && tar xf shellcheck.tar.xz \
  && mv shellcheck-v0.7.2/shellcheck /usr/local/bin/shellcheck \
  && chmod +x /usr/local/bin/shellcheck \
  && rm -Rf shellcheck*



FROM registry.access.redhat.com/ubi8/ubi-minimal:8.4

RUN microdnf install --nodocs \
  git-2.27.0-1.el8.x86_64 \
  findutils-1:4.6.0-20.el8.x86_64 \
  && microdnf clean all

COPY --from=builder /usr/local/bin/hadolint /usr/local/bin/hadolint
COPY --from=builder /usr/local/bin/shellcheck /usr/local/bin/shellcheck

ENV HOME=/home

# allow users to access container as non root (local id mapping) means we do not know who the user id is
RUN chmod 777 /home

WORKDIR /usr/app
