FROM python:3.8-slim-bullseye AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
  git=1:2.30.2-1 \
  gcc=4:10.2.1-1 \
  libpq-dev=13.4-0+deb11u1 \
  python3-dev=3.9.2-3 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/app

ENV HOME=/home

# we do not know what user will be running container
RUN chmod 777 /home

# ensure that private packages are authenticated
RUN --mount=type=secret,id=GITHUB_TOKEN GITHUB_TOKEN=$(cat /run/secrets/GITHUB_TOKEN); git config --global url."https://$GITHUB_TOKEN@github.com/".insteadOf "https://github.com/"

RUN pip install --no-cache-dir \
  'pylint>=2.7.0,<2.8.0' \
  'pytest>=6.1.0,<6.2.0' \
  'safety>=1.9.0,<2.0.0' \
  'pip-licenses>=3.3.0,<3.4.0' \
  'coverage>=5.3.0,<5.4.0' \
  'bandit>=1.7.0,<1.8.0' \
  'pip-check>=2.7.0,<2.8.0'

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

COPY requirements.ci.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt



FROM python:3.8-slim-bullseye

ENV PYLINTHOME="/var/cache/pylint"

ENV HOME=/home

# we do not know what user will be running container
RUN chmod 777 /home

ENV PYTHONPATH=/usr/app

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    git=1:2.30.2-1 \
    jq=1.6-2.1 \
    curl=7.74.0-1.3+b1 \
    libpq-dev=13.4-0+deb11u1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages

COPY --from=builder /usr/local/bin /usr/local/bin

WORKDIR /usr/app
