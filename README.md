# Galaxy Maintenance Docker Container

A Docker image containing the Galaxy packages and tools needed to parse the `galaxy.yml` config file and talk to the Postgresql database, including `psql`, `gxadmin` and the Galaxy maintenance scripts `cleanup_datasets.py`, `pgcleanup.py`, and a modified version of the `maintenanc.sh` script.

## Assumptions
This documentation assumes Galaxy was installed using `galaxy` as the release name and `galaxy` as the namespace.  If you used different values, you will need to adjust the commands accordingly.

## Usage

The easiest way to use the container is to run it as a cron job with a scheduled time that will never occur (Feb 30th in this example). Then trigger the job manually when needed.  This example runs a simple Bash script that waits for a watch file to be created, then exits when it is created.

```bash
helm upgrade galaxy -n galaxy galaxy/galaxy --reuse-values -f templates/admin.yaml
kubectl create job -n galaxy --from=cronjob/galaxy-cron-admin admin-manual
```
The pod that is created with have a random string appeneded to `admin-manual` that we need to find to connect to the pod.

```bash
pod=$(kubectl get pods -n galaxy -l job-name=admin-manual -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n galaxy -it $pod -- /bin/bash
```
To terminate the job, create the watch file.

```bash
kubectl exec -n galaxy $pod -- touch /galaxy/server/database/tmp/debug_watch.lock
# Wait for the job to terminate
kubectl delete job admin-manual
```

## Example CronJob
```yaml
cronJobs:
  admin:
    schedule: "0 0 30 2 *"
    image:
      repository: ksuderman/galaxy-maintenance
      tag: "0.11.5"
    extraEnv:
      - name: WATCH
        value: /galaxy/server/database/tmp/debug_watch.lock
      - name: LOG
        value: /galaxy/server/database/debug.log
      - name: PGHOST
        value: |-
          {{ include "galaxy-postgresql.fullname" . }}
      - name: PGUSER
        value: |-
          {{ .Values.postgresql.galaxyDatabaseUser }}
      - name: PGDATABASE
        value: galaxy
      - name: GALAXY_CONFIG_FILE
        value: /galaxy/server/config/galaxy.yml
      - name: GALAXY_ROOT
        value: /galaxy/server
      - name: GALAXY_LOG_DIR
        value: |-
          {{ .Values.persistence.mountPath}}/tmp
    command:
      - /usr/local/bin/main.sh
    extraFileMappings:
      /usr/local/bin/main.sh:
        mode: "0755"
        content: |
          #!/usr/bin/env bash
          # The .pgpass file needs to be owned by the Galaxy user with 0600
          # permissions.  However, ConfigMap files are always owned by root.  So we
          # need to copy the file to the Galaxy user's home directory and
          # change the ownership and permissions.
          cp /tmp/pgpass /home/galaxy/.pgpass
          sudo chown galaxy:galaxy /home/galaxy/.pgpass
          chmod 0600 /home/galaxy/.pgpass
          while [[ ! -e $WATCH ]] ; do
            # Sleep until the $WATCH file is created
            date | tee $LOG
            sleep 15
          done
          echo "Kill file $WATCH detected." | tee $LOG
          rm $WATCH
      /tmp/pgpass:
        tpl: true
        mode: "0644"
        content: |-
          {{- (include "galaxy-postgresql.fullname" .) }}:5432:*:{{- .Values.postgresql.galaxyDatabaseUser }}:{{- (include "galaxy.galaxyDbPassword" .) }}
      /galaxy/server/config/galaxy.yml:
        tpl: true
        content: |-
          {{- index .Values.configs "galaxy.yml" | toYaml | nindent 4 }}

```

