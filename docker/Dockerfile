# Custom Frappe image for ifitwala_ed (+ its hard dependency ifitwala_drive)
# Follows the frappe_docker "custom apps" layered-build pattern:
# https://github.com/frappe/frappe_docker/blob/main/docs/custom-apps.md
#
# Expects the ifitwala_ed source to be present at ./repo/ifitwala_ed relative
# to the build context (see setup.sh, which clones it there before building).

ARG FRAPPE_BRANCH=version-16-hotfix
ARG PYTHON_VERSION=3.11.9
ARG NODE_VERSION=20.19.2

FROM frappe/bench:latest AS bench

FROM python:${PYTHON_VERSION}-slim-bookworm AS builder

ARG FRAPPE_BRANCH
ARG NODE_VERSION

ARG APP_USER=frappe
ARG APP_HOME=/home/frappe
ARG NVM_DIR=${APP_HOME}/.nvm

ENV APP_USER=${APP_USER} \
    APP_HOME=${APP_HOME} \
    NVM_DIR=${NVM_DIR} \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

RUN useradd -ms /bin/bash ${APP_USER}

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    git \
    vim \
    nginx \
    gettext-base \
    file \
    build-essential \
    cron \
    gpg \
    default-mysql-client \
    libmariadb-dev \
    libwebp-dev \
    libjpeg62-turbo-dev \
    libtiff5-dev \
    libopenjp2-7-dev \
    libpq-dev \
    xfonts-75dpi \
    xfonts-base \
    wget \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

USER ${APP_USER}
WORKDIR ${APP_HOME}

RUN mkdir -p ${NVM_DIR} \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . ${NVM_DIR}/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && nvm use ${NODE_VERSION} \
    && nvm alias default ${NODE_VERSION} \
    && npm install -g yarn \
    && rm -rf ${NVM_DIR}/.cache

ENV PATH=${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${PATH}

RUN pip install --no-cache-dir frappe-bench

RUN bench init \
    --frappe-branch=${FRAPPE_BRANCH} \
    --python=$(which python3) \
    --no-procfile \
    --no-backups \
    --skip-redis-config-generation \
    --verbose \
    ${APP_HOME}/frappe-bench \
    && cd ${APP_HOME}/frappe-bench \
    && rm -rf apps/frappe/.git

WORKDIR ${APP_HOME}/frappe-bench

RUN bench get-app --branch=main ifitwala_drive https://github.com/fderyckel/ifitwala_drive.git \
    && rm -rf apps/ifitwala_drive/.git

COPY --chown=${APP_USER}:${APP_USER} repo/ifitwala_ed apps/ifitwala_ed
RUN rm -rf apps/ifitwala_ed/.git

RUN /home/frappe/.nvm/versions/node/v${NODE_VERSION}/bin/yarn --cwd apps/frappe install || true

RUN bench build --production || true


FROM python:${PYTHON_VERSION}-slim-bookworm AS backend

ARG APP_USER=frappe
ARG APP_HOME=/home/frappe
ARG NODE_VERSION=20.19.2

ENV APP_USER=${APP_USER} \
    APP_HOME=${APP_HOME} \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN useradd -ms /bin/bash ${APP_USER}

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    git \
    curl \
    vim \
    nginx \
    gettext-base \
    file \
    cron \
    gpg \
    default-mysql-client \
    libmariadb3 \
    libwebp7 \
    libjpeg62-turbo \
    libtiff6 \
    libopenjp2-7 \
    libpq5 \
    wkhtmltopdf \
    xfonts-75dpi \
    xfonts-base \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

USER ${APP_USER}
WORKDIR ${APP_HOME}

COPY --from=builder --chown=${APP_USER}:${APP_USER} ${APP_HOME}/frappe-bench ${APP_HOME}/frappe-bench
COPY --from=builder --chown=${APP_USER}:${APP_USER} ${APP_HOME}/.nvm ${APP_HOME}/.nvm

ENV PATH=${APP_HOME}/.nvm/versions/node/v${NODE_VERSION}/bin:${PATH}

RUN pip install --no-cache-dir --user frappe-bench \
    && cd ${APP_HOME}/frappe-bench \
    && pip install --no-cache-dir -e apps/frappe \
    && pip install --no-cache-dir -e apps/ifitwala_drive \
    && pip install --no-cache-dir -e apps/ifitwala_ed

ENV PATH=${APP_HOME}/.local/bin:${PATH}

WORKDIR ${APP_HOME}/frappe-bench

VOLUME [ \
    "${APP_HOME}/frappe-bench/sites", \
    "${APP_HOME}/frappe-bench/sites/assets", \
    "${APP_HOME}/frappe-bench/logs" \
]

EXPOSE 8000 9000

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
USER root
RUN chmod +x /usr/local/bin/entrypoint.sh
USER ${APP_USER}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bench", "start"]
