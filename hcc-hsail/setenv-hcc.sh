HCCPATH=/opt/hcc
HCCVER=3.5.0

echo "Appending hcc tools into PATH"
if [ -z "${PATH}" ]; then
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${HCCPATH}/bin
else
    export PATH=${PATH}:${HCCPATH}/bin
fi

echo "Registering hcc libraries with loader"
echo "${HCCPATH}/lib" >> /etc/ld.so.conf.d/hcc-isa.conf
ldconfig

# if [ -z "${CPATH}" ]; then
#     export CPATH=${HCCPATH}/include
# else
#     export CPATH=${CPATH}:${HCCPATH}/include
# fi

# if [ -z "${LIBRARY_PATH}" ]; then
#     export LIBRARY_PATH=${HCCPATH}/lib
# else
#     export LIBRARY_PATH=${LIBRARY_PATH}:${HCCPATH}/lib
# fi

# if [ -z "${MANPATH}" ]; then
#     export MANPATH=${HCCPATH}/man
# else
#     export MANPATH=${HCCPATH}/man:$MANPATH
# fi

# if [ -z "${INFOPATH}" ]; then
#     export INFOPATH=${HCCPATH}/info
# else
#     export INFOPATH=${HCCPATH}/info:$INFOPATH
# fi
