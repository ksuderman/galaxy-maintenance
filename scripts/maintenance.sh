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
GALAXY_CONFIG_FILE=${GALAXY_CONFIG_FILE:-/galaxy/server/config/galaxy.yml}


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

CMD=/galaxy/server/scripts/cleanup_datasets/cleanup_datasets.py
echo "DAYS      : $DAYS"
echo "CONFIG    : $GALAXY_CONFIG_FILE"
echo "CONNECTION: $GALAXY_CONFIG_OVERRIDE_DATABASE_CONNECTION"
$CMD $GALAXY_CONFIG_FILE -d $DAYS -r --delete_userless_histories
$CMD $GALAXY_CONFIG_FILE -d $DAYS -r --purge_histories
$CMD $GALAXY_CONFIG_FILE -d $DAYS -r --purge_datasets
$CMD $GALAXY_CONFIG_FILE -d $DAYS -r --purge_folders
$CMD $GALAXY_CONFIG_FILE -d $DAYS -r --delete_datasets
$CMD $GALAXY_CONFIG_FILE -d $DAYS -r --purge_datasets

/galaxy/server/scripts/set_user_disk_usage.py -c $GALAXY_CONFIG_FILE

