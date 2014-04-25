#!/usr/bin/env bash

function do_screen() {
    # $1 - name
    # $2 - command to execute

    if (! screen -ls | grep -q ${SESSION_NAME}); then
        screen -S ${SESSION_NAME} -dm -t $1
    else
        screen -S ${SESSION_NAME} -X screen -t $1
    fi
    sleep 1.5
    screen -S ${SESSION_NAME} -p $1 -X stuff "$2"
}


# Make sure we abort on errors or undefined variables
set -e
set -u

SESSION_NAME=${SESSION_NAME:-zwift}

# Make sure we're root.
if [ $(id -u) -ne 0 ]; then
    echo "ERROR: Must be root."
    exit 1
fi

# Check we're running ubuntu 12.04
[ -e /etc/lsb-release ] && source /etc/lsb-release
if [ "${DISTRIB_CODENAME:-unknown}" != "precise" ]; then
    echo "ERROR: This script only works on Ubuntu 12.04 (precise)"
    exit 1
fi

# make sure we have base packages
apt-get update
apt-get install -y python-software-properties curl wget xfsprogs parted memcached

# add ubuntu cloud-archive for swift 1.10 and rax zerovm repo
apt-add-repository cloud-archive:havana --yes
echo "deb [arch=amd64] http://packages.zerovm.org/apt/ubuntu/ precise main" > /etc/apt/sources.list.d/zerovm.list

curl -Sks http://packages.zerovm.org/apt/ubuntu/zerovm.pkg.key | apt-key add -

# update our package lists
apt-get update

# install the swift packages
apt-get install -y swift-object swift-account swift-container swift-proxy swift

# install the zerovm packages
apt-get install -y zerovm-zmq zerocloud

# disable all swift services so they don't start on boot
for svc in /etc/init/swift*.conf; do
    echo "manual" > /etc/init/$(basename ${svc} .conf).override
done

# lay down a swift config
cat > /etc/swift/swift.conf <<EOF
[swift-hash]
swift_hash_path_suffix=
swift_hash_path_prefix=SOMERANDOMSTRING
EOF

cat > /etc/swift/object-server.conf <<EOF
[DEFAULT]
bind_ip = 0.0.0.0
workers = 2

[pipeline:main]
pipeline = object-query object-server
#pipeline = object-server

[app:object-server]
use = egg:swift#object

[object-replicator]

[object-updater]

[object-auditor]

[filter:object-query]
use = egg:zerocloud#object_query
zerovm_timeout = 360
zerovm_maxpool = 10
zerovm_maxinput = 5368709120
zerovm_maxoutput = 5368709120
EOF

cat > /etc/swift/container-server.conf <<EOF
[DEFAULT]
bind_ip = 0.0.0.0
workers = 2

[pipeline:main]
pipeline = container-server

[app:container-server]
use = egg:swift#container

[container-replicator]

[container-updater]

[container-auditor]
EOF

cat > /etc/swift/account-server.conf <<EOF
[DEFAULT]
bind_ip = 0.0.0.0
workers = 2

[pipeline:main]
pipeline = account-server

[app:account-server]
use = egg:swift#account

[account-replicator]

[account-auditor]

[account-reaper]
EOF

cat > /etc/swift/proxy-server.conf <<EOF
[DEFAULT]
bind_ip = 0.0.0.0
bind_port = 8080
workers = 2

[pipeline:main]
pipeline = cache tempauth proxy-query proxy-server
#pipeline = cache tempauth proxy-server

[app:proxy-server]
account_autocreate = true
allow_account_management = false
use = egg:swift#proxy

[filter:cache]
memcache_serialization_support = 2
memcache_servers = 127.0.0.1:11211
use = egg:swift#memcache

[filter:proxy-query]
use = egg:zerocloud#proxy_query
zerovm_maxinput = 5368709120
zerovm_maxoutput = 5368709120

[filter:tempauth]
use = egg:swift#tempauth
user_admin_admin = admin .admin .reseller_admin
user_test_tester = testing .admin
user_test2_tester2 = testing2 .admin
user_test_tester3 = testing3

EOF

mkdir -p /srv/node/disk1

if [ ! -e /srv/disk.img ]; then
    truncate -s 10G /srv/disk.img
    mkfs.xfs -f -i size=512 -d su=64k,sw=1 /srv/disk.img
fi

if ! (grep -q /srv/disk.img /etc/fstab); then
    echo "/srv/disk.img /srv/node/disk1 xfs loop,defaults,noatime,nodiratime,nobarrier,logbufs=8 0 0" > /etc/fstab
fi

mount -a
chown -R swift: /srv/node/disk1

pushd /etc/swift

for which in object container account; do
    if [ ! -e /etc/swift/${which}.builder ]; then
        swift-ring-builder ${which}.builder create 9 1 0
    fi

    declare -A base_ports=(
        [object]=6000
        [container]=6001
        [account]=6002)

    changed=0

    if (! swift-ring-builder ${which}.builder | grep -q 127.0.0.1); then
        swift-ring-builder ${which}.builder add z1-127.0.0.1:${base_ports[${which}]}/disk1 100
        changed=1
    fi

    if [ ${changed} -eq 1 ]; then
        swift-ring-builder ${which}.builder rebalance
    fi
done

popd

chown -R swift: /etc/swift

# set up apache and the redirects
apt-get install -y apache2-mpm-worker git

cat > /etc/apache2/sites-available/default <<EOF
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  ProxyRequests Off
  ProxyPreserveHost On
  ProxyVia On
  DocumentRoot /var/www/zwift-ui

  <Directory />
    Options FollowSymLinks
    AllowOverride None
  </Directory>

  <Directory /var/www/zwift-ui>
    Options Indexes FollowSymlinks Multiviews
    AllowOverride None
    Order allow,deny
    allow from all
  </Directory>

  <Location /auth>
    ProxyPass http://localhost:8080/auth
    ProxyPassReverse http://localhost:8080/auth
  </Location>

  <Location /v1>
    ProxyPass http://localhost:8080/v1
    ProxyPassReverse http://localhost:8080/v1
  </Location>

  <Location /open>
    ProxyPass http://localhost:8080/open
    ProxyPassReverse http://localhost:8080/open
  </Location>

  ErrorLog \${APACHE_LOG_DIR}/error.log

  LogLevel warn

  CustomLog \${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
EOF

# turn on some apache mods
a2enmod proxy
a2enmod proxy_http
a2ensite default

service apache2 restart

# pull latest ui
pushd /var/www
git clone https://github.com/zerovm/zwift-ui
popd

if (screen -ls | grep -q ${SESSION_NAME}); then
    screen -X -S ${SESSION_NAME} -p 0 -X quit
fi

for service in proxy object container account; do
    echo "starting ${service}..."
    do_screen ${service} "/usr/bin/swift-${service}-server -v /etc/swift/${service}-server.conf"$'\n'
done

screen -S ${SESSION_NAME} -X screen -t shell
screen -DR
