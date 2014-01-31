#!/bin/bash 
# This script installs the zerovm project from git in an easily
# buildable manner.

# Debug and error handling
if [[ -n "${DEBUG}" ]]; then
    set -x
fi
set -e

TMPDIR=$(mktemp -d)

function clean_up {
    info "Cleaning up and exiting"
    rm -rf ${TMPDIR}
}
trap clean_up SIGHUP SIGINT SIGTERM EXIT


# Setup
BASE_REPO="https://github.com/zerovm"
declare -a REQUIRED_PKGS=(libc6-dev-i386 libglib2.0-dev pkg-config git 
    build-essential automake autoconf libtool g++-multilib texinfo flex
    bison groff gperf texinfo subversion libpgm-5.1 flex bison groff
    libncurses5-dev libexpat1-dev)

ZVM_USER=zerovm
ZVM_PATH=/home/zerovm
export ZEROVM_ROOT=${ZEROVM_ROOT:-${ZVM_PATH}/zerovm}
export ZVM_PREFIX=${ZVM_PREFIX:-${ZVM_PATH}/zvm-root}
export ZRT_ROOT=${ZRT_ROOT:-${ZVM_PATH}/zrt}

if ! declare -p ZVM_PROJECTS &>/dev/null; then
    declare -a ZVM_PROJECTS=(zrt zerovm toolchain zerovm-cli gcc glibc newlib binutils linux-headers-for-nacl validator)
fi

declare -A ZVM_REPOS=()

for project in "${ZVM_PROJECTS[@]}"; do
    ZVM_REPOS[$project]=${ZVM_REPOS[$project]:-${BASE_REPO}/${project}}
done

if ! declare -p ZVM_OVERRIDE_PATHS &>/dev/null; then
    declare -A ZVM_OVERRIDE_PATHS=(
        [validator]="${ZEROVM_ROOT}/valz"
        [linux-headers-for-nacl]="${ZVM_PATH}/toolchain/SRC/linux-headers-for-nacl"
        [gcc]="${ZVM_PATH}/toolchain/SRC/gcc"
        [glibc]="${ZVM_PATH}/toolchain/SRC/glibc"
        [newlib]="${ZVM_PATH}/toolchain/SRC/newlib"
        [binutils]="${ZVM_PATH}/toolchain/SRC/binutils"
    )
fi

function install-pkgs {
    info "Ensuring dependencies are installed."
    DEBCONF_FRONTEND="noninteractive"  apt-get install -y --allow-unauthenticated -o DPkg::Options::="--force-confdef" -o DPkg::Options::="--force-confold"  "${@}"
}


function install-deps {
    install-pkgs "${@}"
    mkdir ${TMPDIR}/debs
    pushd ${TMPDIR}/debs
    if ! dpkg -l libzmq3 &>/dev/null || ! dpkg -l libzmq3-dev &>/dev/null; then
	info "Manually installing zeromq 4.0.1"
        wget http://zvm.rackspace.com/v1/repo/ubuntu/pool/main/z/zeromq3/libzmq3_4.0.1-ubuntu1_amd64.deb
        wget http://zvm.rackspace.com/v1/repo/ubuntu/pool/main/z/zeromq3/libzmq3-dev_4.0.1-ubuntu1_amd64.deb
        DEBCONF_FRONTEND="noninteractive" dpkg --force-confdef --force-confold -i *.deb
    fi
    popd
}

function clone_or_update {
    local project=${1}
    shift
    local path=${ZVM_OVERRIDE_PATHS[$project]:-${ZVM_PATH}/${project}}
    if [[ -d "${path}" ]]; then
	info "Project '${project}' has already been cloned.  Running git pull."
        pushd "${path}"
        sudo -u ${ZVM_USER} git pull
        popd
    else
	info "Cloning project '${project}' to path '${path}'"
        sudo -u ${ZVM_USER} git clone ${ZVM_REPOS[$project]} $path
    fi
}

function add_line_if_not_exists {
    file="${1}"
    shift
    line="${@}"
    if grep -v "^${line}\$" ${file} & >/dev/null; then
	info "Adding line '$line' to file '$file'"
	echo "${line}" >> ${file}
    else
	info "File '$file' already contains line '${line}'"
    fi
}

function save_settings {
    f="${ZVM_PATH}/zerovm.sh"
    if ! [[ -f "${f}" ]]; then
	info "Saving environment variables to '${f}'"
        cat >${f} <<EOF
export ZEROVM_ROOT=${ZEROVM_ROOT}
export ZVM_PREFIX=${ZVM_PREFIX}
export ZRT_ROOT=${ZRT_ROOT}
export DESTDIR=${ZVM_PREFIX}
echo "See ${ZVM_OVERRIDE_PATHS[zrt]:-${ZVM_PATH}/zrt}/readme.md for build instructions."
echo "We have conveniently already installed deps and configured your environment variables as follows:"
echo "ZEROVM_ROOT=\${ZEROVM_ROOT}"
echo "ZVM_PREFIX=\${ZVM_PREFIX}"
echo "ZRT_ROOT=\${ZRT_ROOT}"
echo "DESTDIR=\${ZVM_PREFIX}" # important for the validator make install
EOF
    else
	info "File '${f}' already exists.  Skipping save settings."
    fi
    eval HOMEDIR="$(printf "~%q" "${ZVM_USER}")"
    add_line_if_not_exists "${HOMEDIR}/.bashrc"  "source '${f}'"
}

function add-user {
    u=$1
    shift
    if getent passwd ${u}; then
	info "User '${u}' already exists.  Skipping useradd."
    else
	info "Adding user '${u}'"
	useradd -m ${u} -s /bin/bash -d "${ZVM_PATH}" &>/dev/null || true
    fi
}

function main {
    add-user ${ZVM_USER}
    install-deps "${REQUIRED_PKGS[@]}"
    mkdir -p ${ZVM_PATH}
    mkdir -p ${ZVM_PREFIX}
    pushd "${ZVM_PATH}"
    for p in "${ZVM_PROJECTS[@]}"; do
        clone_or_update "$p"
    done
    save_settings
    popd
}

function info {
    if [[ -n "${VERBOSE}" ]]; then
	echo "${@}" 1>&2
    fi
}

main
