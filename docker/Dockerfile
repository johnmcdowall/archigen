ARG RUBY_VERSION=3.2.2
FROM ruby:${RUBY_VERSION}-slim

ARG FOLDERS_TO_REMOVE
ARG BUNDLE_WITHOUT
ARG RAILS_ENV
ARG NODE_ENV

# Tool versions
ARG NODE_MAJOR=20
ARG YARN_VERSION=1.22.19
ARG BUNDLER_VERSION=2.4.13

ENV DEBIAN_FRONTEND=noninteractive \
    RAILS_ENV=${RAILS_ENV} \
    NODE_ENV=${NODE_ENV} \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true \
    BUNDLE_WITHOUT=${BUNDLE_WITHOUT} \
    PAGER=more \
    LANG=C.UTF-8

ENV OVERMIND_VERSION=2.3.0 \
    OVERMIND_SHA256=d6a715c0810ceb39c94bf61843befebe04a83a0469b53d6af0a52e2fea4e2ab3 \
    OVERMIND_SOCKET=/tmp/.overmind_socket \
    OVERMIND_NO_PORT=1 \
    OVERMIND_SKIP_ENV=true \
    OVERMIND_TMUX_CONFIG=/home/devuser/.config/tmux/tmux.conf

# Install packages
RUN apt-get update -q -o=Dpkg::Use-Pty=0 > /dev/null 2>&1 && \
    apt-get install -qy --no-install-recommends \
    # Needed for SSL curling
    ca-certificates \
    # Needed for package building
    autoconf \
    build-essential \
    # Needed for curling packages
    curl \
    # Needed for cloning git gem sources
    git \
    # Needed for yarn install
    gnupg2 \
    # Libs generally needed for various rubygems
    libpq-dev \
    postgresql-client-15 \
    libsqlite3-dev \
    libreadline-dev \
    tzdata \
    file \
    openssh-client \
    git \
    libvips \
    libjemalloc2 \
    zsh \
    stow \
    # TMux needed for overmind
    tmux \
    vim && \
    # Clear out logs
    apt-get clean -o=Dpkg::Use-Pty=0 > /dev/null 2>&1 && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/lib/apt/lists/* && \
    truncate -s 0 /var/log/*log

# Install Node and Yarn. Happens after package install because we need curl.
RUN curl -sL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - > /dev/null 2>&1 && \
    apt-get install -o=Dpkg::Use-Pty=0 -y nodejs > /dev/null 2>&1 && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt update -o=Dpkg::Use-Pty=0 > /dev/null 2>&1 && \
    apt install -y yarn=$YARN_VERSION-1 > /dev/null 2>&1 && \
    yarn config set cache-folder /yarn && \
    # Clear out logs
    apt-get clean -o=Dpkg::Use-Pty=0 > /dev/null 2>&1 && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/lib/apt/lists/* && \
    truncate -s 0 /var/log/*log

# Install Overmind for Procfile support
RUN curl --fail -Lo overmind.gz https://github.com/DarthSim/overmind/releases/download/v${OVERMIND_VERSION}/overmind-v${OVERMIND_VERSION}-linux-amd64.gz; \
    echo "${OVERMIND_SHA256} *overmind.gz" | sha256sum -c - >/dev/null 2>&1; \
    zcat overmind.gz > /usr/local/bin/overmind; \
    chmod +x /usr/local/bin/overmind; \
    rm overmind.gz; \
    # smoke test
    [ "$(command -v overmind)" = '/usr/local/bin/overmind' ]; \
    overmind --version | grep -q "${OVERMIND_VERSION}"

ENV LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="background_thread:true,metadata_thp:auto,dirty_decay_ms:5000,muzzy_decay_ms:5000,narenas:2" \
    RUBY_YJIT_ENABLE="1"

WORKDIR /rails

# Download the Maxmind GeoIP db locally for geocoding use. Right now I'm
# using my (JMD's) public Google Drive...
RUN mkdir /rails/db && curl -sL "https://drive.google.com/uc?export=download&id=1xIu-2vOqkMqHaBBDcDrolcpIBVPwMYP6" --output /rails/db/GeoLite2-City.mmdb

# We don't care about deprecation warnings.
RUN echo "RUBYOPT=-W:no-deprecated" >> /etc/environment && \
    # Update the system rubygems
    #gem update --silent --system > /dev/null 2>&1 && \
    gem install -v ${BUNDLER_VERSION} bundler --force > /dev/null 2>&1

# We don't care about deprecation warnings, or local Gem docs.
RUN echo "export RUBYOPT=-W:no-deprecated" >> ~/.profile && \
    echo "gem: --no-document" >> ~/.gemrc && \
    # Record the date and time of the build
    date -u > /rails/BUILD_TIME

COPY --chown=devuser:devuser ./Gemfile* /rails/
COPY --chown=devuser:devuser package.json yarn.lock /rails/

# Install all app dependencies
RUN --mount=type=cache,id=-gem-cache,sharing=locked,target=/rails/.cache/bundle \
    bundle config --local without "staging production omit" && \
    bundle config set app_config /rails/.bundle && \
    bundle config set path /rails/.cache/bundle && \
    bundle install --jobs $(nproc) --retry 3 && \
    yarn install --quiet

# Get the container time zone to match the host time zone.
RUN ln -sf /usr/share/zoneinfo/hostlocaltime /etc/localtime

# Add user
RUN addgroup --gid 1000 --system devuser && \
    adduser \
    --system -u 1000 --ingroup devuser --gecos '' \
    --home /home/devuser --shell /bin/bash \
    devuser

# Make the bundled gems etc accessible by the `devuser` user.
RUN chown -R devuser:devuser /usr/local && \
    mkdir -p /rails/tmp/cache && \
    mkdir -p /rails/db && \
    chown -R devuser:devuser /rails

USER devuser:devuser

ADD --chown=devuser:devuser . /rails

# vim: ft=Dockerfile
