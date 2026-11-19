#!/bin/sh

PASSPHRASE=jDEj2z5pGUuFt2DUuFEFtz5pkNpGpkNF
SIGNATURE_SIZE=256
CERTIFICATE=/mnt/flash/Public_bin.crt

set -e 

trap 'cleanup' EXIT

cleanup()
{
    test -n "${TMPDIR}" && test -d ${TMPDIR} && rm -rf ${TMPDIR}
}


die() {
    >&2 echo Error: $@
    exit 1
}

get_file_size()
{
    stat $1  | grep -oe "Size: [0-9]*" | cut -d' ' -f 2
}

create_tempdir()
{
    TMPDIR=$(mktemp -d /root/installer.XXXXXX)
}

decrypt_file() {
    local infile=$1
    local outfile=$2
    local passphrase=$3

    openssl aes-256-cbc -pass pass:${passphrase} -md md5 -d -in ${infile} -out ${outfile} || die "Can not decrypt ${filename}"
}

split_signature() {
    local decrypted_file=$1
    local signature_file=$2
    local signature_size=$3
    local file_size=$(get_file_size ${decrypted_file})

    tail -c ${signature_size} ${decrypted_file} > ${signature_file} || die "Could not extract signature"
    2>/dev/null dd if=/dev/null of=${decrypted_file} bs=$((file_size-signature_size)) seek=1 || die "Could not truncate file"
}

get_certificate()
{
    if test -f ${CERTIFICATE}; then
        echo ${CERTIFICATE}
    else
        echo ${EXECDIR}/Public_bin.crt
    fi
}

extract_public_key_from_certificate()
{
    local certificate=$1
    local pubkey_file=$2
    openssl x509 -in "${certificate}" -pubkey -noout > "${pubkey_file}" || die "Could not extrac public key from certificate"
}

verify_signature()
{
    local filename=$1
    local pubkey_file=$2
    local signature=$3
    local algo=$4

    openssl dgst -${algo} -verify "${pubkey_file}" -signature "${signature}" "$filename" >/dev/null 2>/dev/null || die "Signature verification failed!" 
}

decrypt_and_verify()
{
    local infile=$1
    local decrypted_file=$2
    local signature=${TMPDIR}/signature
    local pubkey=${TMPDIR}/pubkey
    local algo=sha${SIGNATURE_SIZE}
    local certificate=$(get_certificate)

    extract_public_key_from_certificate ${certificate} ${pubkey} || die "Could not acquire pubkey"
    decrypt_file $infile ${decrypted_file} ${PASSPHRASE} || die "Could not decrypt"
    split_signature ${decrypted_file} ${signature} ${SIGNATURE_SIZE} || die "Could not split file"
    verify_signature ${decrypted_file} ${pubkey} ${signature} ${algo} || die "Signature verification failed"
}

test $# -eq 2 || die "Usage $(basename $0) <filename> <path>"
filename=$1
path=$2

test -f ${filename} || die "File ${filename} does not exist"
create_tempdir || die "Can not create tmp dir"

cd ${TMPDIR}

decrypt_and_verify ${filename} ${TMPDIR}/personality_decrypted.tgz 1>/dev/null
tar -zxf ${TMPDIR}/personality_decrypted.tgz || die "Can not extract personality package"
personality=$(find ${TMPDIR} -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

test -n ${personality} || die "No personality found"

test -d /sbin/personalities/${personality} && die "Personality is built-in"
test -d ${path} || mkdir -p ${path} || die "Can not create personality base path"
test -d ${path}/${personality} && die "Personality exists, will not replace"


mv ${TMPDIR}/${personality} ${path}/${personality} || die "Can not install personality ${personality}"
echo ${personality}
