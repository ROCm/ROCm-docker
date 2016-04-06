ROCR_PATH=/opt/hsa

echo "Registering hsa libraries with loader"
echo "${ROCR_PATH}/lib" >> /etc/ld.so.conf.d/rocr.conf
ldconfig
