#!/bin/bash

/opt/rocm/bin/rocminfo 2>&1 | /bin/grep "HSA Error" > /dev/null
if [ $? -eq 0 ]
then
    echo "Error: Incompatible ROCm environment."
    echo "The Docker container requires the latest kernel driver to operate correctly."
    echo "Upgrade the ROCm kernel to v4.1 or newer, or use a container tagged for v4.0.1 or older."
    echo "For more information, see"
    echo "https://rocmdocs.amd.com/en/latest/Current_Release_Notes/Current-Release-Notes.html#"
    exit 1
fi
exec "$@"
