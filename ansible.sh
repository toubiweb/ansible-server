#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$BASE_DIR/config"

# exit on first failure
#set -e

# print commands
# set -x

die () {
    echo >&2 "$@"
    exit 1
}

# https://stackoverflow.com/a/21189044/1097926
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}


for i in "$@"
do
    case $i in
        --config=*)
            config="${i#*=}"
            shift # past argument=value
        ;;
        --role=*)
            role="${i#*=}"
            shift # past argument=value
        ;;
        -v)
            verbose="-vvvv"
            shift # past argument=value
        ;;
        --verbose)
            verbose="-vvvv"
            shift # past argument=value
        ;;
        *)
            # unknown option
            echo Unknown option "${i#*=}"
        ;;
    esac
done

roles=("traefik" "nginx-proxy")
targets=("localhost" "s1.toubiweb.com")

if [ -z $role ]
then
    
    echo ""
    PS3="Please select a role:"
    
    select role in "${roles[@]}"
    do
        echo $role
        break;
    done
    
fi

if [ $(contains "${roles[@]}" "$role") != "y" ]; then
    echo ""
    die "[ERROR] Invalid role $role, availables: ${roles[@]}"
fi

if [ -z $config ]
then
    
    echo ""
    prompt="Please select a configuration file:"
    options=( $(find $CONFIG_DIR -maxdepth 1 -name "*.yml" -printf "%f\n") )
    
    PS3="$prompt "
    select config in "${options[@]}" "Quit" ; do
        if (( REPLY == 1 + ${#options[@]} )) ; then
            exit
            
            elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
            
            break
            
        else
            echo "Invalid option. Try another one."
        fi
    done
fi

CONFIG_FILEPATH="$CONFIG_DIR/$config"

ANSIBLE_TAGS="$role"
ANSIBLE_EXTRA_VARS="CONFIG_FILEPATH=$CONFIG_FILEPATH"

echo ""
echo "###################################################################################"
echo ""
echo "./ansible.sh --role=$role --config=$config"
echo ""
echo "###################################################################################"
echo ""

## parse and eval yaml file
eval $(parse_yaml config/$config)

if [ "$target_machine" == "localhost" ]
then
    echo ""
    echo "[LOCAL MACHINE]"
    echo ""
    set -x
    sudo ansible-playbook $verbose -i "localhost," -c local $BASE_DIR/ansible.cookbook.yml --verbose --tags "$ANSIBLE_TAGS" --extra-vars "$ANSIBLE_EXTRA_VARS"
    set +x
else
    echo ""
    echo "[REMOTE SERVER]"
    echo "$target_machine"
    echo ""
    set -x
    ansible-playbook $verbose ansible.cookbook.yml -l $target_machine --tags "$ANSIBLE_TAGS" --ask-become-pass --extra-vars "$ANSIBLE_EXTRA_VARS"
fi

echo ""
echo "###################################################################################"
echo ""
echo "./ansible.sh --role=$role --config=$config"
echo ""
echo "###################################################################################"
echo ""
