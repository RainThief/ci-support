FROM registry.access.redhat.com/ubi8/ubi-minimal:8.4 as builder

ENV HOME=/home

RUN microdnf install --nodocs \
	curl-7.61.* \
	git-2.27.* \
	unzip-6.0-* \
	ca-certificates-2021.2* \
	findutils-1:4.* \
	&& \
	git clone https://github.com/tfutils/tfenv.git ~/.tfenv && \
	echo "PATH=${HOME}/.tfenv/bin:${PATH}" >> ~/.bashrc && \
  microdnf clean all

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -fsSL https://github.com/aquasecurity/tfsec/releases/download/v0.58.6/tfsec-linux-amd64 -o /usr/local/bin/tfsec && chmod +x /usr/local/bin/tfsec && \
	export TFLINT_VERSION="v0.32.1" && curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
	. ~/.bashrc && tfenv install 0.13.7 && tfenv use 0.13.7

# Following environment variable will allow us to use .terraform-version
# within terraform projects to install and set the required version dynamically
# by tfenv, therefore base version of terraform available is hardcoded to 0.13.7,
# but can be overridden by .terraform-version file in the project root.
ENV TFENV_AUTO_INSTALL=true

WORKDIR /usr/app

ENTRYPOINT ["/bin/bash"]
