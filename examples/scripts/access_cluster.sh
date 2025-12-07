#!/bin/bash
set -euo pipefail

HELP_TEXT=(
  'Usage: '
  '       --start [PATH]  Prepare and start ssh port forwarding.
                          Recommended to run this command with
                          eval $('$0' --start)
                          to automatically export KUBECONFIG env variable to your current shell
                          [PATH] is an optional path parameter to the terraform root directory. 
                          If not set, the parent directory is assumed.'
  '       --ssh-key       Optional path to ssh key used to connect to remote controller.'
  '       --stop          kills the ssh process and thus stops ssh port forwarding, requires sudo.'
  '       --help          Show this help and exit.'
)
RED='\033[0;31m'
NC='\033[0m'


usage(){
  echo -e "${RED}${1:-}${NC}" >&2
  if [[ ${2:-} == 0 ]]; then
    printf "%s\n" "${HELP_TEXT[@]}"
  else
    printf "%s\n" "${HELP_TEXT[@]}" >&2
  fi
  exit "${2:-0}"
}

getAbsDir(){
  if [[ ! -d $1 ]]; then
    usage "Directory $1 does not to exist" 2
  fi
  cd $1 || usage "Cannot retrieve absolute path for $1" 2
  pwd
  cd - > /dev/null
}

# Set default base dir to parent directory, assuming this script is in a /scripts directory
BASE_DIR=$(getAbsDir "$(dirname "$0")/..")

# Command line flag parsing
FLAGS_START=0
FLAGS_STOP=0
SSH_KEY_OPTION=""

while (( $# )); do
  case "$1" in
    --start) FLAGS_START=1; shift
      if [[ ! -z ${1:-} && $1 != --* ]]; then
        BASE_DIR=$(getAbsDir "$1")
        shift
      fi
    ;;
    --ssh-key)
      shift
      if [[ -z "${1:-}" ]]; then
        usage "Error: --ssh-key requires a path argument" 2
      fi
      SSH_KEY_OPTION="-i ${1}"
      shift
      ;;
    --stop)  FLAGS_STOP=1; shift ;;
    --help)  usage "" 0 ;;
    --*)     usage "Unknown option: $1" 2 ;;
    *)       usage "Unexpected argument: $1" 2 ;;
  esac
done

# Flag validation
if (( FLAGS_START + FLAGS_STOP == 0 )); then
  usage "Error: one of --start or --stop is required" 2
fi
if (( FLAGS_START + FLAGS_STOP > 1 )); then
  usage "Error: --start and --stop are mutually exclusive" 2
fi
if [[ $FLAGS_START == 1 ]]; then
  # check return value of ls in order to determine if this is a valid terraform root directory
  if  ! ls -la $BASE_DIR/terraform.tfstate >/dev/null 2>&1; then
    usage "Error: No terraform state file found in $BASE_DIR. Did you forget to add the path parameter to your terraform root directory?" 2
  fi
fi

REMOTE_USER="debian"
LOCAL_PORT=6443
REMOTE_FORWARD_PORT=6443

# Port forwarding start / stop logic
if [[ $FLAGS_START == 1 ]]; then
    cd $BASE_DIR
    PUBLIC_IP=$(terraform output -raw controller_public_ip)
    scp debian@$PUBLIC_IP:/etc/rancher/k3s/k3s.yaml ./k3s-remote.yaml
    PRIVATE_IP=$(cat k3s-remote.yaml | grep server | cut -d ":" -f3 | sed -r 's/\/+//g')

    ssh -f -N -T -L $LOCAL_PORT:$PRIVATE_IP:$REMOTE_FORWARD_PORT $REMOTE_USER@$PUBLIC_IP $SSH_KEY_OPTION

    cp k3s-remote.yaml k3s-local.yaml
    sed -i "s/$PRIVATE_IP/localhost/g" k3s-local.yaml
    # echo export statement so that the user either can copy and paste it
    # or run eval $(./scripts/access_cluster.sh --start)
    echo "export KUBECONFIG=${BASE_DIR}/k3s-local.yaml"
    cd - > /dev/null
elif [[ $FLAGS_STOP == 1 ]]; then
    OUTPUT=$(ps ax | grep "ssh -f -N -T -L $LOCAL_PORT" | grep -v "grep") || OUTPUT=""
    if [[ -z $OUTPUT ]]; then 
      echo "No ssh process was running listening on $LOCAL_PORT"
      exit 0
    fi

    PID=$(echo $OUTPUT | cut -d " " -f1)
    echo "Killing ssh process $PID with port forwarding on $LOCAL_PORT"
    sudo kill $PID
    echo "Port forwarding stopped."
fi