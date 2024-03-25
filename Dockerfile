FROM python:3.10-slim

ARG GALAXY_USER=galaxy

# We create the galaxy user first because something we `apt install` below
# creates a system user 'messagebus' that will grab uid 101 if we don't
RUN adduser --system --group --uid 101 --home /home/$GALAXY_USER $GALAXY_USER \
    && mkdir -p /galaxy/server/scripts \
    && mkdir /galaxy/server/config \
	&& chown -R $GALAXY_USER:$GALAXY_USER /galaxy/server

RUN apt update && apt install -y \
    bsdmainutils \
    curl \
    sudo \
    postgresql-client \
    emacs \
    iputils-ping

# Install gxadmin
RUN curl -JLo /usr/local/bin/gxadmin https://github.com/galaxyproject/gxadmin/releases/latest/download/gxadmin \
	&& chmod +x /usr/local/bin/gxadmin

RUN pip install --no-cache \
	galaxy-app \
	galaxy-config \
	galaxy-data \
	galaxy-objectstore \
	galaxy-schema \
	galaxy-util \
    psycopg2-binary \
    sqlalchemy==1.4.51

# Allow the galaxy user to run sudo
RUN echo "galaxy	ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/galaxy
COPY scripts /galaxy/server/scripts/
# TODO remove when/if the galaxy-app package includes this file.
COPY files/carbon_intensity.csv /usr/local/lib/python3.10/site-packages/galaxy/carbon_emissions

USER $GALAXY_USER

ENTRYPOINT /bin/bash
