HSATHK_INSTALL_PATH=/opt/rocm/libhsakmt/lib/x86_64-linux-gnu
HSATHK_SYSTEM_PATH=/usr/lib/x86_64-linux-gnu

echo "Copying hsa thunk into system directory"
rm -f ${HSATHK_SYSTEM_PATH}/libhsakmt.*
cp -a ${HSATHK_INSTALL_PATH}/lib*.so* ${HSATHK_SYSTEM_PATH}
