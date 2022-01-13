FROM registry.access.redhat.com/ubi8/ubi-minimal:8.4 as builder

RUN microdnf install --nodocs \
    curl-7.61.* \
	  unzip-6.0-* \
    && microdnf clean all

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -L https://releases.hashicorp.com/terraform/1.1.3/terraform_1.1.3_linux_amd64.zip -o "terraform.zip" \
  && unzip terraform.zip \
  && mv /terraform /usr/local/bin/terraform \
  && chmod +x /usr/local/bin/terraform \
  && rm -Rf terraform*

ENV HOME=/home

RUN curl -L https://github.com/aquasecurity/tfsec/releases/download/v0.63.1/tfsec-linux-amd64 -o /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

ARG TFLINT_VERSION="v0.34.1"

RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash



FROM registry.access.redhat.com/ubi8/ubi-minimal:8.4

RUN microdnf install --nodocs \
    findutils-1:4.* \
    diffutils-3.6* \
    git-2.27.* \
    && microdnf clean all

COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=builder /usr/local/bin/tflint /usr/local/bin/tflint
COPY --from=builder /usr/local/bin/tfsec /usr/local/bin/tfsec

ENV HOME=/home

ENV TFLINT_PLUGIN_DIR=/usr/app/build/tflint.d

WORKDIR /usr/app
