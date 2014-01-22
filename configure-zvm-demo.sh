#!/bin/bash

# This script installs zerovm from packages

# Debug and error handling
if [[ -n "${DEBUG}" ]]; then
    set -x
fi
set -e

TMPDIR=$(mktemp -d)
pushd ${TMPDIR}

function clean_up {
    info "Cleaning up and exiting"
    rm -rf ${TMPDIR}
}
trap clean_up SIGHUP SIGINT SIGTERM EXIT

function info {
    if [[ -n "${VERBOSE}" ]]; then
	echo "${@}" 1>&2
    fi
}

function add-user {
    u=$1
    shift
    password=$1
    if getent passwd ${u} &>/dev/null; then
	info "User '${u}' already exists.  Skipping useradd."
    else
	info "Adding user '${u}'"
	useradd -m ${u} -s /bin/bash -d "/home/${u}" &>/dev/null || true
	if [[ -n "${password}" ]]; then
	    echo "${user}:${password}" | chpasswd
	fi
	touch /etc/user.list
	chmod 600 /etc/user.list
	echo "${user}:${password}" >> /etc/user.list
    fi
}

function add-line-if-not-exists {
    local file="${1}"
    shift
    local line="${@}"
    if ! grep "^${line}\$" ${file} &>/dev/null; then
        info "Adding line '$line' to file '$file'"
        echo "${line}" >> ${file}
    else
        info "File '$file' already contains line '${line}'"
    fi
}

function create-zerovm-user
{
    local user=${1}
    local password=$(grep "^${user}:" /etc/user.list | cut -d: -f2)
    if [[ -z "${password}" ]]; then
	# tempauth requires base64 encoding of usernames / passwords with _.  Let's skip that.
	password=$(until pwgen -1 | grep -v _; do :; done)
    fi
    
    if ! [[ -d /usr/share/design-summit ]]; then
	git clone https://github.com/ludditry/design-summit /usr/share/design-summit
    else
	pushd /usr/share/design-summit
	git pull
	popd
    fi
    add-user ${user} ${password}
    add-swift-user "${user}" "${user}" "${password}"
    pushd /home/${user}
    if ! [[ -d design-summit ]]; then
	su ${user} -c "git clone /usr/share/design-summit"
    else
	pushd design-summit
	su ${user} -c "git pull"
	popd
    fi
    popd
    echo "export ST_AUTH=http://localhost:8080/auth/v1.0
export ST_USER=${user}:${user}
export ST_KEY=${password}
" > /home/${user}/zvmrc
    add-line-if-not-exists /home/${user}/.bashrc "source ~/zvmrc"
}

function add-swift-user {
    tenant=$1
    user=$2
    password=$3
    add-line-if-not-exists /etc/swift/proxy-server.conf "user_${tenant}_${user} = ${password} .admin"
}

function install-prereqs {
    apt-get update
    apt-get install -y curl wget git make build-essential pwgen
    if ! [[ -f /etc/swifted ]]; then
	info "attempting to install zwift!"
	curl -skS https://raw.github.com/ludditry/design-summit/master/zwift-aio/bootstrap.sh | bash && touch /etc/swifted
    fi

    if ! [[ -f /usr/local/bin/rescreen.sh ]]; then
	info "downloading rescreen.sh"
	wget https://github.com/ludditry/design-summit/blob/master/zwift-aio/rescreen.sh -O /usr/local/bin/rescreen.sh
    fi
    chmod +rx /usr/local/bin/rescreen.sh
    apt-get install -y gcc-4.4.3-zerovm gdb-zerovm zerovm-cli
}

function main {
    install-prereqs
    for u in zerovm{1..75}; do
	create-zerovm-user $u
    done
    pkill screen || true
    for svc in object container account proxy; do
	swift-init $svc stop
	swift-init $svc start
    done
}

main
popd
