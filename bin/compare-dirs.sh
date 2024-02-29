#!/bin/bash

# Utility for comparing files in different directories
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -euo pipefail

function usage()
{
    echo "usage ${0} <directory one> <directory two> [<output directory>]"
    echo "where <directory one> and <directory two> are directories to be compared"
    echo "if <output directory> is not specified $HOME/compare-dir is used"
    echo "The output directory must not already exist, it is created by the script"
}

function compare_file()
{
    local src dest diff_result
    src="${1:-}"
    dest="${2:-}"

    if [ -f  "${dest}" ] ; then
        echo "comparing ${src} and ${dest}"
        mkdir -p `dirname "${out_dir}${src}.patch"`
        set +e
        diff "${src}" "${dest}" > "${out_dir}${src}.patch"
        diff_result="$?"
        set -e
        if [ "${diff_result}" != "0" ] ; then
            echo "files different, see ${out_dir}${src}.patch"
        else
            rm "${out_dir}${src}.patch"
        fi
    else
        echo "${src} found but ${dest} not present"
    fi
}

function compare_dir()
{
    local src dest file_dir
    src="${1:-}"
    dest="${2:-}"
    if [ ! -d "$src" ] ; then
        echo "${src} is not a directory"
        return
    fi
    if [ ! -d "$dest" ] ; then
        echo "${src} is a directory but ${dest} is not"
        return
    fi
    echo "comparing files in ${src} and ${dest}"
    for file_dir in `ls -c1 "${src}"`
    do
        if [ -d "$src/$file_dir" ] ; then
            compare_dir "$src/$file_dir" "$dest/$file_dir"
        else
            compare_file "$src/$file_dir" "$dest/$file_dir"
        fi
    done
}

dir1="${1:-}"
if [ -z "${dir1}" ]; then
    usage
    exit 1
fi

dir2="${2:-}"
if [ -z "${dir2}" ]; then
    usage
    exit 1
fi

out_dir="${3:-}"
if [ -z "${out_dir}" ]; then
    out_dir=$HOME/compare-dir
fi
if [ -e "${out_dir}" ] ; then
    usage
    echo "output directory: ${out_dir} already exists, delete and rerun script"
    exit 1
fi

mkdir "${out_dir}"

compare_dir `realpath $dir1` `realpath $dir2`

