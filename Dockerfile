FROM python:3.12-slim

ARG GALAXY_USER=galaxy

RUN pip install --no-cache \
	galaxy-app \
	galaxy-config \
	galaxy-data \
	galaxy-objectstore \
	galaxy-schema \
	galaxy-util
COPY scripts/* /usr/local/bin/
COPY files/carbon_intensity.csv /usr/local/lib/python3.12/site-packages/galaxy/carbon_emissions
RUN adduser --system --group --uid 101 $GALAXY_USER \
	&& mkdir /etc/galaxy \
	&& chown $GALAXY_USER:$GALAXY_USER /etc/galaxy

USER $GALAXY_USER

ENTRYPOINT /bin/bash
