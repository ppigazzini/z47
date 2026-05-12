#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
allowlist_file="$script_dir/zig-c-boundaries.txt"

declare -a cimport_allowed=()
declare -a extern_allowed=()

contains_path() {
    local needle="$1"
    shift

    local candidate
    for candidate in "$@"; do
        if [[ "$candidate" == "$needle" ]]; then
            return 0
        fi
    done

    return 1
}

load_allowlist() {
    local section=""
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            "" | \#*)
                continue
                ;;
            "[cimport]")
                section="cimport"
                continue
                ;;
            "[extern-symbols]")
                section="extern"
                continue
                ;;
        esac

        case "$section" in
            cimport)
                cimport_allowed+=("$line")
                ;;
            extern)
                extern_allowed+=("$line")
                ;;
            *)
                printf 'Entry outside allowlist section: %s\n' "$line" >&2
                exit 1
                ;;
        esac
    done < "$allowlist_file"
}

require_allowlisted_match() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if [[ ! -f "$repo_root/$file" ]]; then
        printf 'Allowlisted %s file is missing: %s\n' "$label" "$file" >&2
        return 1
    fi

    if ! grep -Eq "$pattern" "$repo_root/$file"; then
        printf 'Allowlisted %s file no longer matches guard pattern: %s\n' "$label" "$file" >&2
        return 1
    fi

    return 0
}

check_tree() {
    local violations=0
    local file

    mapfile -t zig_files < <(cd "$repo_root" && git ls-files -- '*.zig')

    for file in "${cimport_allowed[@]}"; do
        require_allowlisted_match "$file" '@cImport[[:space:]]*\(' '@cImport' || violations=1
    done

    for file in "${extern_allowed[@]}"; do
        require_allowlisted_match "$file" '^[[:space:]]*(pub[[:space:]]+)?extern[[:space:]]+(fn|const|var)\b' 'extern-symbol' || violations=1
    done

    for file in "${zig_files[@]}"; do
        if grep -Eq '@cImport[[:space:]]*\(' "$repo_root/$file"; then
            if ! contains_path "$file" "${cimport_allowed[@]}"; then
                printf 'Unapproved @cImport boundary: %s\n' "$file" >&2
                violations=1
            fi
        fi

        if grep -Eq '^[[:space:]]*(pub[[:space:]]+)?extern[[:space:]]+(fn|const|var)\b' "$repo_root/$file"; then
            if ! contains_path "$file" "${extern_allowed[@]}"; then
                printf 'Unapproved direct extern symbol binding: %s\n' "$file" >&2
                violations=1
            fi
        fi
    done

    if [[ "$violations" -ne 0 ]]; then
        exit 1
    fi
}

load_allowlist
check_tree

printf 'Approved @cImport files: %s\n' "${#cimport_allowed[@]}"
printf 'Approved extern-symbol files: %s\n' "${#extern_allowed[@]}"