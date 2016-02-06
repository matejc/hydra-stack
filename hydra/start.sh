#!/bin/bash -xe

export HOME=/home/hydra

DB_ADDR="`getent hosts hydra-db | awk '{ print $1 }'`"
export HYDRA_DBI=`echo $HYDRA_DBI | sed "s/hydra-db/$DB_ADDR/"`

function gen_signing_key {
    openssl genrsa -out /etc/nix/signing-key.sec 2048
    openssl rsa -in /etc/nix/signing-key.sec -pubout > /etc/nix/signing-key.pub
}

function wait_for_nix_sh {
    while [ ! -f /home/hydra/.nix-profile/etc/profile.d/nix.sh ]
    do
        echo "waiting for nix.sh"
        sleep 1
    done
}

function wait_for_db {
    while ! echo hydra | psql -l -h $DB_ADDR &>/dev/null
    do
        echo "waiting for postgres"
        sleep 1
    done
}

function hydra_init {

    function admin_init {

        if [[ $HYDRA_USERNAME && ${HYDRA_USERNAME-x} && $HYDRA_FULLNAME && ${HYDRA_FULLNAME-x} && $HYDRA_EMAIL && ${HYDRA_EMAIL-x} && $HYDRA_PASSWORD && ${HYDRA_PASSWORD-x} ]]
        then
            hydra-create-user $HYDRA_USERNAME --full-name "$HYDRA_FULLNAME" --email-address $HYDRA_EMAIL --password $HYDRA_PASSWORD --role admin && \
                touch "$HYDRA_DATA/admin_init"
        else
            echo "HYDRA_USERNAME or HYDRA_FULLNAME or HYDRA_EMAIL or HYDRA_PASSWORD are not set!"
            exit 1
        fi
    }

    wait_for_db

    hydra-init

    test -f "$HYDRA_DATA/admin_init" || admin_init
}

function find_builders {
    test -f /etc/nix/machines && rm /etc/nix/machines
    test -f $HOME/.ssh/known_hosts && rm $HOME/.ssh/known_hosts
    for i in `seq 1 $1`
    do
        BUILDER="`getent hosts builder$i | awk '{ print $1 }'`"
        if nc -q 1 $BUILDER 22 </dev/null &>/dev/null
        then
            echo "nix@$BUILDER x86_64-linux $HOME/.ssh/id_rsa 1 1" >> /etc/nix/machines
            ssh-keyscan -t rsa builder$i,$BUILDER >> $HOME/.ssh/known_hosts
        fi
    done
}

case "$1" in
    'hydra_init')
        hydra_init
        ;;
    'hydra-server')
        wait_for_nix_sh && source $HOME/.profile
        wait_for_db
        hydra-server hydra-server -f -p 3000 -d
        ;;
    'hydra-evaluator')
        wait_for_nix_sh && source $HOME/.profile
        wait_for_db
        hydra-evaluator hydra-evaluator
        ;;
    'hydra-queue-runner')
        wait_for_nix_sh && source $HOME/.profile
        wait_for_db
        hydra-queue-runner --unlock
        function kill-queue-runner {
            pkill -INT hydra-queue-runner
            hydra-queue-runner --unlock
        }
        trap 'kill-queue-runner' SIGINT
        hydra-queue-runner -v
        ;;
    'hydra-update-gc-roots')
        wait_for_nix_sh && source $HOME/.profile
        hydra-update-gc-roots hydra-update-gc-roots
        ;;
    'hydra-send-stats')
        wait_for_nix_sh && source $HOME/.profile
        wait_for_db
        hydra-send-stats hydra-send-stats
        ;;
    'init')
        test -d /nix/store || cp -a /nix2/* /nix/
        chown -R hydra /nix

        source $HOME/.profile

        mkdir -p $HOME/.ssh
        test -f $HOME/.ssh/id_rsa || ssh-keygen -t rsa -b 2048 -f $HOME/.ssh/id_rsa -q -N ""
        chown -R hydra:100 $HOME
        chmod -R 700 $HOME

        mkdir -p /home/nix/.ssh
        cat $HOME/.ssh/id_rsa.pub > /home/nix/.ssh/authorized_keys
        chown -R 1000:100 /home/nix
        chmod -R 700 /home/nix
        chmod 600 /home/nix/.ssh/authorized_keys

        find_builders 10

        test -f /etc/nix/signing-key.sec || gen_signing_key

        echo "statsd_host = `getent hosts statsd | awk '{ print $1 }'`" > $HYDRA_DATA/hydra.conf
        chown -R hydra $HYDRA_DATA

        su hydra -c "$0 hydra_init"
esac
