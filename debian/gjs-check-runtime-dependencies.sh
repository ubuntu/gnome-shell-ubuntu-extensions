#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2025 Canonical Ltd.
# SPDX-License-Identifier: GPL-3.0-or-later
# Author: Marco Trevisan

set -eu

sources_root=${1:-.}
action=${2:-invalid-action}

if ! command -v gjs >/dev/null; then
    echo "gjs is required, but was not found"
    exit 1
fi

ignored_typelibs=(
    AppIndicator3
    Clutter
    Cogl
    Meta
    Mtk
    Shell
    St
    versions
)

function in_array() {
    local value=$1
    shift

    for v in "${@}"; do
        if [[ "$v" == "$value" ]]; then
            return 0
        fi
    done

    return 1
}

function introspect_typelibs() {
    local introspect_path=$1
    local included_typelibs=()
    mapfile -t included_typelibs < <(
        grep "gi://.*" "${introspect_path}" -rho |
        sed "s,gi://\([A-Za-z0-9]\+\)\(?version=\([0-9\.]\+\)\)\?.*,\1-\3,g" |
        sort -u
    )

    local imported_typelib=()
    mapfile -t imported_typelib < <(
        grep "imports\.gi\.[A-Za-z0-9]\+" "${introspect_path}" -rho |
        sed "s,imports\.gi\.\(.\+\),\1,g" |
        sort -u
    )

    local all_typelibs=("${included_typelibs[@]}")
    for typelib in "${imported_typelib[@]}"; do
        if ! in_array "$typelib" "${all_typelibs[@]}"; then
            all_typelibs+=("$typelib")
        fi
    done

    local any_skipped=
    for typelib in "${all_typelibs[@]}"; do
        namespace=${typelib%-*}
        version=${typelib#*-}

        full_name=$namespace
        if [ -n "$version" ]; then
            full_name="$typelib"
        fi

        if in_array "$full_name" "${ignored_typelibs[@]}"; then
            echo "Skipping $full_name"
            any_skipped=1
            continue
        fi

        typelibs+=("$full_name")
    done

    if [ -n "$any_skipped" ]; then
        echo
    fi
}

function check_dependencies() {
    local failed=()

    for typelib in "${typelibs[@]}"; do
        local namespace=${typelib%-*}
        local version=

        if [[ "$typelib" == *-* ]]; then
            version=${typelib#*-}
        fi

        local code=()
        if [ -n "$version" ]; then
            code+=("imports.gi.versions.$namespace = '$version'")
        fi

        code+=("imports.gi.${namespace}")

        if ! gjs -c "$(printf "%s;" "${code[@]}")" 2>/dev/null; then
            failed+=("$typelib")
            continue
        fi

        echo "${typelib%-}"
    done

    if [ -n "${failed[*]}" ]; then
        echo
        echo "Failed resolving some dependencies:"
        printf "%s\n" "${failed[@]}" | sort -u
        return 1
    fi
}

function find_dependencies() {
    deps=()
    failed=()

    for typelib in "${typelibs[@]}"; do
        if [[ "$typelib" != *-* ]]; then
            local version

            version=$(gjs -c "print(imports.gi.$typelib.__version__)" 2>/dev/null || true)

            if [ -z "$version" ]; then
                failed+=("$typelib")
                continue
            fi

            typelib="$typelib-$version"
        fi

        local query="girepository-1.0/${typelib}.typelib"
        local dep

        dep=$(dpkg -S "$query" 2>/dev/null| cut -f1 -d: | head -1)
        if [ -z "$dep" ]; then
            failed+=("$typelib")
            continue
        fi

        deps+=("$dep")
    done

    echo "Found dependencies:"
    printf "%s\n" "${deps[@]}" | sort -u

    if [ -n "${failed[*]}" ]; then
        echo
        echo "Failed resolving some dependencies, missing installed packages?"
        printf "%s\n" "${failed[@]}" | sort -u
        return 1
    fi
}

typelibs=()

if [ "$action" = "check" ]; then
    introspect_typelibs "${sources_root}"/subprojects
    check_dependencies
elif [ "$action" = "dependencies" ]; then
    introspect_typelibs "${sources_root}"/subprojects
    find_dependencies
else
    echo "Unknown action: $action"
    exit 1
fi
