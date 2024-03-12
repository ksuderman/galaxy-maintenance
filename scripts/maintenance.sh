#!/usr/bin/env bash

# Configure this script in a cron job to run some common cleanup operations
# Set the Environment variable GALAXY_CONFIG_FILE to use a custom galaxy config file.

set -e

display_help(){
  scriptname=$(basename "$0")
  printf "./$scriptname [--help] [--no-dry-run] [--days 10] 
Will run the galaxy cleanup scripts in the recommend order. By default a 'dry-run' is started. Specify --no-dry-run to do the actual cleanup.

--help                  Show this help
-c|--config             Path to the Galaxy config file
--days                  Number of days to use as a cut off; do not act on objects updated more recently than this
"
}

# number of days to use as a cut off; do not act on objects updated more recently than this
DAYS=10
DRYRUN=true
GALAXY_CONFIG_FILE=/etc/galaxy/galaxy.yml


while [[ $# > 0 ]] ; do
  case "$1" in
    -c|--config)
      GALAXY_CONFIG_FILE=$2
      shift
      ;;
    --days )
      DAYS="$2"
      shift
      ;;
    -h|--help )
      display_help
      exit 1
      ;;
    *)
      echo "Invalid option $1"
      exit 1
      ;;
  esac
  shift
done

#cd "$(dirname "$0")"/..

# . scripts/common_startup_functions.sh
# 
# setup_python
# 
# set_galaxy_config_file_var

#if [ "$DRYRUN" = true ]; then
#  MODE="--info_only"
#else
#  MODE="-r"
#fi

#whoami
#ls -alh /etc/galaxy
MODE=-r

echo "DAYS  : $DAYS"
echo "CONFIG: $GALAXY_CONFIG_FILE"
/usr/local/bin/cleanup_datasets.py $GALAXY_CONFIG_FILE -d $DAYS $MODE --delete_userless_histories
/usr/local/bin/cleanup_datasets.py $GALAXY_CONFIG_FILE -d $DAYS $MODE --purge_histories
/usr/local/bin/cleanup_datasets.py $GALAXY_CONFIG_FILE -d $DAYS $MODE --purge_datasets
/usr/local/bin/cleanup_datasets.py $GALAXY_CONFIG_FILE -d $DAYS $MODE --purge_folders
/usr/local/bin/cleanup_datasets.py $GALAXY_CONFIG_FILE -d $DAYS $MODE --delete_datasets
/usr/local/bin/cleanup_datasets.py $GALAXY_CONFIG_FILE -d $DAYS $MODE --purge_datasets

/usr/local/bin/set_user_disk_usage.py
