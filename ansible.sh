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
    PS3="Select a role:"
    
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
    
    prompt="Please select a configuration file:"
    options=( $(find $CONFIG_DIR -maxdepth 1 -name "*.yml" -print0 | xargs -0) )
    
    PS3="$prompt "
    select CONFIG_FILEPATH in "${options[@]}" "Quit" ; do
        if (( REPLY == 1 + ${#options[@]} )) ; then
            exit
            
            elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
            
            CONFIG_DIR_SIZE=${#CONFIG_DIR}
            config="${CONFIG_FILEPATH:$CONFIG_DIR_SIZE+1}"
            
            break
            
        else
            echo "Invalid option. Try another one."
        fi
    done
else
    CONFIG_FILEPATH="$CONFIG_DIR/$config"
fi


ANSIBLE_TAGS="$role"
ANSIBLE_EXTRA_VARS="CONFIG_FILEPATH=$CONFIG_FILEPATH"

echo ""
echo "###################################################################################"
echo ""
echo "./ansible.sh --role=$role --config=$config"
echo ""
echo "###################################################################################"
echo ""

if [ "$config" == "localhost.yml" ]
then
    env=dev
else
    env=prod
fi
if [ "$env" == "prod" ];
then
    ansible-playbook $verbose ansible.cookbook.yml -l $target --tags "$ANSIBLE_TAGS" --ask-become-pass --extra-vars "$ANSIBLE_EXTRA_VARS"
else
    echo ""
    echo "[dev]"
    echo ""
    set -x
    sudo ansible-playbook $verbose -i "localhost," -c local $BASE_DIR/ansible.cookbook.yml --verbose --tags "$ANSIBLE_TAGS" --extra-vars "$ANSIBLE_EXTRA_VARS"
    set +x
fi
echo ""
echo "###################################################################################"
echo ""
echo "./ansible.sh --role=$role --config=$config"
echo ""
echo "###################################################################################"
echo ""
