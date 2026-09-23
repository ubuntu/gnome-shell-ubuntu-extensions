#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2025 Canonical Ltd.
# SPDX-License-Identifier: GPL-3.0-or-later
# Author: Marco Trevisan

set -eu

sources_root=${1:-.}
action=${2:-invalid-action}

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

function format_typelib() {
    local typelib=$1

    if [[ "$typelib" == *@* ]]; then
        printf '%s-%s\n' "${typelib%@*}" "${typelib#*@}"
    else
        printf '%s\n' "$typelib"
    fi
}

function introspect_typelibs() {
    local introspect_path=$1
    local all_typelibs=()
    mapfile -t all_typelibs < <(
        find "${introspect_path}" -type f \( -name "*.js" -o -name "*.mjs" -o -name "*.cjs" \) -exec perl -0ne '
            my $text = $_;
            my $module_sanitized = "";
            my $code_sanitized = "";
            my @states = ("code");
            my @template_expr_depth = ();
            my $escape = 0;
            my $single_quote = chr(39);
            my $double_quote = chr(34);
            my $dollar = chr(36);
            my $open_brace = chr(123);
            my $close_brace = chr(125);
            my $backtick = chr(96);

            for (my $i = 0; $i < length($text); $i++) {
                my $char = substr($text, $i, 1);
                my $next = $i + 1 < length($text) ? substr($text, $i + 1, 1) : "";
                my $state = $states[-1];

                if ($state eq "line_comment") {
                    if ($char eq "\n") {
                        pop @states;
                        $module_sanitized .= "\n";
                        $code_sanitized .= "\n";
                    } else {
                        $module_sanitized .= " ";
                        $code_sanitized .= " ";
                    }
                    next;
                }

                if ($state eq "block_comment") {
                    if ($char eq "*" && $next eq "/") {
                        $module_sanitized .= "  ";
                        $code_sanitized .= "  ";
                        $i++;
                        pop @states;
                    } elsif ($char eq "\n") {
                        $module_sanitized .= "\n";
                        $code_sanitized .= "\n";
                    } else {
                        $module_sanitized .= " ";
                        $code_sanitized .= " ";
                    }
                    next;
                }

                if ($state eq "single" || $state eq "double" || $state eq "template") {
                    if ($state eq "template" && !$escape && $char eq $dollar && $next eq $open_brace) {
                        $module_sanitized .= q|${|;
                        $code_sanitized .= q|${|;
                        push @states, "template_expr";
                        push @template_expr_depth, 1;
                        $i++;
                        next;
                    }

                    $module_sanitized .= $char;
                    $code_sanitized .= $char eq "\n" ? "\n" : " ";
                    if ($escape) {
                        $escape = 0;
                    } elsif ($char eq "\\") {
                        $escape = 1;
                    } elsif (($state eq "single" && $char eq $single_quote) ||
                             ($state eq "double" && $char eq $double_quote) ||
                             ($state eq "template" && $char eq $backtick)) {
                        pop @states;
                    }
                    next;
                }

                if ($char eq "/" && $next eq "/") {
                    $module_sanitized .= "  ";
                    $code_sanitized .= "  ";
                    $i++;
                    push @states, "line_comment";
                    next;
                }

                if ($char eq "/" && $next eq "*") {
                    $module_sanitized .= "  ";
                    $code_sanitized .= "  ";
                    $i++;
                    push @states, "block_comment";
                    next;
                }

                if ($char eq $single_quote) {
                    $module_sanitized .= $char;
                    $code_sanitized .= " ";
                    $escape = 0;
                    push @states, "single";
                    next;
                } elsif ($char eq $double_quote) {
                    $module_sanitized .= $char;
                    $code_sanitized .= " ";
                    $escape = 0;
                    push @states, "double";
                    next;
                } elsif ($char eq $backtick) {
                    $module_sanitized .= $char;
                    $code_sanitized .= " ";
                    $escape = 0;
                    push @states, "template";
                    next;
                }

                if ($state eq "template_expr") {
                    if ($char eq $open_brace) {
                        $template_expr_depth[-1]++;
                    } elsif ($char eq $close_brace) {
                        $template_expr_depth[-1]--;
                    }

                    $module_sanitized .= $char;
                    $code_sanitized .= $char;

                    if ($char eq $close_brace && $template_expr_depth[-1] == 0) {
                        pop @template_expr_depth;
                        pop @states;
                    }
                    next;
                }

                $module_sanitized .= $char;
                $code_sanitized .= $char;
            }

            while ($module_sanitized =~ /(?:^|[^[:alnum:]_\$])import\s*\(\s*["\047`](gi:\/\/[A-Za-z0-9_-]+(?:\?version=[0-9.]+)?)["\047`](?:\s*,[\s\S]*?)?\s*\)/gms) {
                print("$1\n");
            }

            while ($module_sanitized =~ /(?:^|[^[:alnum:]_\$])import\s+(?:[\s\S]*?\sfrom\s*)?["\047`](gi:\/\/[A-Za-z0-9_-]+(?:\?version=[0-9.]+)?)["\047`]/gms) {
                print("$1\n");
            }

            while ($module_sanitized =~ /(?:^|[^[:alnum:]_\$])export\s+[\s\S]*?\sfrom\s*["\047`](gi:\/\/[A-Za-z0-9_-]+(?:\?version=[0-9.]+)?)["\047`]/gms) {
                print("$1\n");
            }

            while ($code_sanitized =~ /(?:^|[^[:alnum:]_\$])imports\.gi\.([A-Za-z0-9_]+)/gms) {
                print("$1\n");
            }
        ' {} \; |
        sed -E "s,^gi://([A-Za-z0-9_-]+)\\?version=([0-9.]+)$,\1@\2,; s,^gi://([A-Za-z0-9_-]+)$,\1," |
        sort -u
    )

    local any_skipped=
    for typelib in "${all_typelibs[@]}"; do
        local namespace=$typelib
        local version=
        if [[ "$typelib" == *@* ]]; then
            namespace=${typelib%@*}
            version=${typelib#*@}
        fi

        local full_name
        full_name=$(format_typelib "$typelib")

        if in_array "$namespace" "${ignored_typelibs[@]}"; then
            echo "Skipping $full_name"
            any_skipped=1
            continue
        fi

        typelibs+=("$typelib")
    done

    if [ -n "$any_skipped" ]; then
        echo
    fi
}

function require_gjs() {
    if ! command -v gjs >/dev/null; then
        echo "gjs is required, but was not found"
        exit 1
    fi
}

function check_dependencies() {
    local failed=()

    for typelib in "${typelibs[@]}"; do
        local namespace=$typelib
        local version=
        if [[ "$typelib" == *@* ]]; then
            namespace=${typelib%@*}
            version=${typelib#*@}
        fi

        local display_typelib
        display_typelib=$(format_typelib "$typelib")

        local code=()
        if [ -n "$version" ]; then
            code+=("imports.gi.versions.$namespace = '$version'")
        fi

        code+=("imports.gi.${namespace}")

        if ! gjs -c "$(printf "%s;" "${code[@]}")" 2>/dev/null; then
            failed+=("$display_typelib")
            continue
        fi

        echo "$display_typelib"
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
        local namespace=$typelib
        local version=
        if [[ "$typelib" == *@* ]]; then
            namespace=${typelib%@*}
            version=${typelib#*@}
        fi

        if [ -z "$version" ]; then
            local resolved_version

            resolved_version=$(gjs -c "print(imports.gi.$namespace.__version__)" 2>/dev/null || true)

            if [ -z "$resolved_version" ]; then
                failed+=("$namespace")
                continue
            fi
            version=$resolved_version
        fi

        local resolved_typelib="${namespace}-${version}"
        local query="girepository-1.0/${resolved_typelib}.typelib"
        local dep

        dep=$(dpkg -S "$query" 2>/dev/null| cut -f1 -d: | head -1)
        if [ -z "$dep" ]; then
            failed+=("$resolved_typelib")
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
    require_gjs
    introspect_typelibs "${sources_root}"/subprojects
    check_dependencies
elif [ "$action" = "dependencies" ]; then
    require_gjs
    introspect_typelibs "${sources_root}"/subprojects
    find_dependencies
elif [ "$action" = "extract" ]; then
    introspect_typelibs "${sources_root}"/subprojects
    for typelib in "${typelibs[@]}"; do
        format_typelib "$typelib"
    done | sort -u
else
    echo "Unknown action: $action"
    exit 1
fi
