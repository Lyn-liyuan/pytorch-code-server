FROM pytorch/pytorch:1.8.1-cuda10.2-cudnn7-devel

# Install dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential \
  curl \
  ca-certificates \
  dumb-init \
  htop \
  git \
  bzip2 \
  libx11-6 \
  locales \
  man \
  nano \
  git \
  procps \
  openssh-client \
  vim.tiny \
  lsb-release \
  python3-pip \
  && rm -rf /var/lib/apt/lists/*
RUN pip install opencv-python --quiet 

RUN sed -i "s/# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen \
  && locale-gen
ENV LANG=en_US.UTF-8



# Create a non-root user
RUN adduser --disabled-password --gecos '' --shell /bin/bash coder

#RUN echo "coder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-coder




# Install fixuid
ENV ARCH=amd64
RUN curl -fsSL "https://github.com/boxboat/fixuid/releases/download/v0.4.1/fixuid-0.4.1-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
  chown root:root /usr/local/bin/fixuid && \
  chmod 4755 /usr/local/bin/fixuid && \
  mkdir -p /etc/fixuid && \
  printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

# Install code-server
WORKDIR /tmp
ENV CODE_SERVER_VERSION=3.12.0
RUN curl -fOL https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_${ARCH}.deb
RUN dpkg -i ./code-server_${CODE_SERVER_VERSION}_${ARCH}.deb && rm ./code-server_${CODE_SERVER_VERSION}_${ARCH}.deb
COPY ./entrypoint.sh /usr/bin/entrypoint.sh

# Switch to default user
USER coder

ENV PASSWORD=${PASSWORD:-P@ssw0rd}

ENV USER=coder

# Create project directory
RUN mkdir -p /home/coder/workspace && \
    mkdir -p /home/coder/.local && \
    chown -R coder:coder /home/coder && \
    chown -R coder:coder /home/coder/.local && \
    chown -R coder:coder /home/coder/workspace;

ENV HOME=/home/coder
WORKDIR /home/coder/workspace

RUN /usr/bin/code-server --install-extension ms-python.python && \
    /usr/bin/code-server --install-extension esbenp.prettier-vscode && \
    /usr/bin/code-server --install-extension equinusocio.vsc-material-theme && \
    /usr/bin/code-server --install-extension codezombiech.gitignore && \
    /usr/bin/code-server --install-extension piotrpalarz.vscode-gitignore-generator && \
    /usr/bin/code-server --install-extension aeschli.vscode-css-formatter && \
    /usr/bin/code-server --install-extension donjayamanne.githistory && \
    /usr/bin/code-server --install-extension ecmel.vscode-html-css && \
    /usr/bin/code-server --install-extension pkief.material-icon-theme && \
    /usr/bin/code-server --install-extension equinusocio.vsc-material-theme-icons && \
    /usr/bin/code-server --install-extension eg2.vscode-npm-script && \
    /usr/bin/code-server --install-extension ms-ceintl.vscode-language-pack-zh-hans && \
    /usr/bin/code-server --install-extension dbaeumer.vscode-eslint

EXPOSE 8090

ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8090", "--cert", "--disable-telemetry", "."]
