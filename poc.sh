#!/bin/bash
set -e

CONTAINER="../moss-container/build/moss-container"

if [[ ! -e "${CONTAINER}" ]]; then
    echo "Missing moss-container"
    exit 1
fi

UNION_TREE="./union"
TOOL_TREE="./tools"

function buildUnion()
{
    mkdir -p "$UNION_TREE"
    mkdir -p "$TOOL_TREE"

    # usr-merge it
    for i in lib lib64 bin sbin ; do
        ln -sfv usr/$i "${UNION_TREE}/${i}"
    done
}


buildUnion

${CONTAINER} \
    -u 0 -n \
    -d "${UNION_TREE}" \
    -s PATH="/bootstrap/bin:/usr/bin:/usr/sbin" \
    -s TERM="xterm-256color" \
    --bind-ro=/usr=/usr \
    --bind-ro=/run=/run \
    --bind-ro=/etc=/etc \
    --bind-ro=$(pwd)/tools=/bootstrap \
    --bind-rw=$(pwd)/stages/stage0/binutils=/testing \
    -- \
    boulder bi /testing/stone.yml -o /testing/ -a x86_64-stage1 -u -d
