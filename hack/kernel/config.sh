#!/bin/bash

case $KERNEL_EDITION in
    aurae)
        export KERNEL_PREFIX="aurae"
        export KERNEL_VERSION=5.15.68
        export KERNEL_CONFIG="aurae-linux-${KERNEL_VERSION}.config"
        ;;

    firecracker)
        export KERNEL_PREFIX="firecracker"
        export KERNEL_VERSION=5.10.143
        export KERNEL_CONFIG="firecracker-linux-${KERNEL_VERSION}.config"
        ;;
    
    *)
        echo "Please select kernel edition by providing KERNEL_EDITION variable (values: 'aurae', 'firecracker')."
        exit 1
        ;;

esac