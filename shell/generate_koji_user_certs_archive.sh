#!/bin/sh

user=$1
tmp_cert_dir=/tmp/koji_temp_cert
archive_name=${user}_koji_certs.tar.bz2

rm -rf $tmp_cert_dir
mkdir -p $tmp_cert_dir
cp /etc/koji.conf $tmp_cert_dir/
cp /etc/pki/koji/koji_ca_cert.crt $tmp_cert_dir/clientca.crt
cp /etc/pki/koji/koji_ca_cert.crt $tmp_cert_dir/serverca.crt
cp /etc/pki/koji/${user}.pem $tmp_cert_dir/client.crt
cp /etc/pki/koji/certs/${user}_browser_cert.p12 $tmp_cert_dir/

pushd ${tmp_cert_dir}
tar cfj /tmp/${archive_name} .
popd

#tar cfj /tmp/${archive_name} ${tmp_cert_dir}/*

echo "Get archive here /tmp/${archive_name}"
