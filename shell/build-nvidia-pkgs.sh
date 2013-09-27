#!/bin/sh

nvidia_version=$1

if [ "1${nvidia_version}" == "1" ]; then
    echo "Run as $0 <nvidia drivers version>"
    exit 1
fi

function download_source {
    url=$1
    wget_cmd="/usr/bin/wget"
    if [ -x $wget_cmd ]; then
        $wget_cmd $url
    else
        echo "wget not found. Try curl..."
        curl_cmd="/usr/bin/curl"
        if [ -x $curl_cmd ]; then
            $curl_cmd -O $url
        else
            echo "curl not found. Fatal."
            exit 1
        fi
    fi
}


nvidia_source_url_x32="http://http.download.nvidia.com/XFree86/Linux-x86/${nvidia_version}/NVIDIA-Linux-x86-${nvidia_version}.run"
nvidia_source_url_x64="http://http.download.nvidia.com/XFree86/Linux-x86_64/${nvidia_version}/NVIDIA-Linux-x86_64-${nvidia_version}.run"

nvidia_source_x32="NVIDIA-Linux-x86-${nvidia_version}"
nvidia_source_x64="NVIDIA-Linux-x86_64-${nvidia_version}"

if [ ! -f ${nvidia_source_x32}.run ]; then
    download_source ${nvidia_source_url_x32}
fi

if [ ! -f ${nvidia_source_x64}.run ]; then
    download_source ${nvidia_source_url_x64}
fi

# Extract packages
if [ -d ${nvidia_source_x32} ]; then
    rm -rf ${nvidia_source_x32}
fi
if [ -d ${nvidia_source_x64} ]; then
    rm -rf ${nvidia_source_x64}
fi

sh ${nvidia_source_x32}.run -x
sh ${nvidia_source_x64}.run -x

# Generate nvidia-kmod source
mkdir -p nvidiapkg-x86 nvidiapkg-x64
cp -R ${nvidia_source_x32}/kernel ${nvidia_source_x32}/LICENSE nvidiapkg-x86/
cp -R ${nvidia_source_x64}/kernel ${nvidia_source_x64}/LICENSE nvidiapkg-x64/

tar cfJ nvidia-kmod-data-${nvidia_version}.tar.xz nvidiapkg-x86 nvidiapkg-x64
