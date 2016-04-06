HCC_PATH=/opt/hcc
HCC_VER=3.5.0

echo "Appending hcc tools into PATH"
if [ -z "${PATH}" ]; then
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${HCC_PATH}/bin
else
    export PATH=${PATH}:${HCC_PATH}/bin
fi

echo "Registering hcc libraries with loader"
echo "${HCC_PATH}/lib" >> /etc/ld.so.conf.d/hcc-isa.conf
ldconfig

# if [ -z "${CPATH}" ]; then
#     export CPATH=${HCC_PATH}/include
# else
#     export CPATH=${CPATH}:${HCC_PATH}/include
# fi

# if [ -z "${LIBRARY_PATH}" ]; then
#     export LIBRARY_PATH=${HCC_PATH}/lib
# else
#     export LIBRARY_PATH=${LIBRARY_PATH}:${HCC_PATH}/lib
# fi

# if [ -z "${MANPATH}" ]; then
#     export MANPATH=${HCC_PATH}/man
# else
#     export MANPATH=${HCC_PATH}/man:$MANPATH
# fi

# if [ -z "${INFOPATH}" ]; then
#     export INFOPATH=${HCC_PATH}/info
# else
#     export INFOPATH=${HCC_PATH}/info:$INFOPATH
# fi
