#!/bin/sh

#sudo mkdir -p /run/dbus && sudo dbus-daemon --system --nofork --nopidfile &

UID=${UID:-$(id -u)}
GID=$(id -g)
export XDG_RUNTIME_DIR=/run/user/${UID}
[ -d ${XDG_RUNTIME_DIR} ] || sudo mkdir -p ${XDG_RUNTIME_DIR} \
	&& sudo chown ${UID}:${GID} ${XDG_RUNTIME_DIR} \
	&& sudo chmod 700 ${XDG_RUNTIME_DIR}
exec dbus-launch --exit-with-session bash -l
