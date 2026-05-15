#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
manifest_file="$script_dir/source-ownership.txt"
pin_file="$script_dir/upstream-pin.env"

z47_roots=()
imported_roots=()
approved_imported_additions=()

trim_line() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s\n' "$value"
}

load_manifest() {
    local section=""
    local raw_line line

    while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
        line="${raw_line%%#*}"
        line="$(trim_line "$line")"
        [[ -z "$line" ]] && continue

        case "$line" in
            "[z47-owned]")
                section="z47"
                continue
                ;;
            "[imported-upstream]")
                section="imported"
                continue
                ;;
            "[approved-z47-additions-under-imported]")
                section="approved"
                continue
                ;;
        esac

        case "$section" in
            z47)
                z47_roots+=("$line")
                ;;
            imported)
                imported_roots+=("$line")
                ;;
            approved)
                approved_imported_additions+=("$line")
                ;;
            *)
                printf 'Entry outside known section in %s: %s\n' "$manifest_file" "$line" >&2
                exit 1
                ;;
        esac
    done < "$manifest_file"

    if [[ "${#z47_roots[@]}" -eq 0 || "${#imported_roots[@]}" -eq 0 ]]; then
        printf 'Source ownership manifest must classify both z47-owned and imported roots.\n' >&2
        exit 1
    fi
}

require_tracked_root() {
    local root="$1"

    if ! git ls-tree --name-only HEAD -- "$root" | grep -Fx -- "$root" >/dev/null; then
        printf 'Manifest entry is not tracked at HEAD: %s\n' "$root" >&2
        exit 1
    fi
}

validate_manifest_coverage() {
    declare -A classified=()
    local root

    for root in "${z47_roots[@]}" "${imported_roots[@]}"; do
        if [[ -n "${classified[$root]+x}" ]]; then
            printf 'Duplicate root classification in %s: %s\n' "$manifest_file" "$root" >&2
            exit 1
        fi
        classified[$root]=1
        require_tracked_root "$root"
    done

    local missing=0
    while IFS= read -r root; do
        [[ -z "$root" ]] && continue
        if [[ -z "${classified[$root]+x}" ]]; then
            printf 'Tracked top-level path is missing from %s: %s\n' "$manifest_file" "$root" >&2
            missing=1
        fi
    done < <(git ls-tree --name-only HEAD | sort)

    if [[ "$missing" -ne 0 ]]; then
        exit 1
    fi
}

is_approved_imported_addition() {
    local path="$1"
    local approved

    for approved in "${approved_imported_additions[@]}"; do
        [[ -z "$approved" ]] && continue
        if [[ "$path" == "$approved" || "$path" == "$approved"/* ]]; then
            return 0
        fi
    done

    return 1
}

print_roots() {
    local root
    for root in "$@"; do
        printf '%s\n' "$root"
    done
}

check_added_imported_paths() {
    # shellcheck disable=SC1090
    . "$pin_file"

    if ! git rev-parse --verify --quiet "$UPSTREAM_COMMIT^{commit}" >/dev/null; then
        printf 'Pinned upstream commit %s is not present locally. Fetch %s %s before running %s.\n' \
            "$UPSTREAM_COMMIT" \
            "$UPSTREAM_REPOSITORY_URL" \
            "$UPSTREAM_BRANCH" \
            "$0" >&2
        exit 1
    fi

    local diff_base
    if ! diff_base="$(git merge-base "$UPSTREAM_COMMIT" HEAD)"; then
        printf 'Unable to resolve a merge base between HEAD and pinned upstream commit %s.\n' "$UPSTREAM_COMMIT" >&2
        exit 1
    fi

    local added_paths=()
    mapfile -t added_paths < <(git diff --name-only --diff-filter=A "$diff_base"..HEAD -- "${imported_roots[@]}")

    local violations=0
    local path
    for path in "${added_paths[@]}"; do
        if is_approved_imported_addition "$path"; then
            continue
        fi

        printf 'Unapproved added file under imported upstream roots: %s\n' "$path" >&2
        violations=1
    done

    if [[ "$violations" -ne 0 ]]; then
        printf 'Additions under imported upstream roots require an explicit exception in %s.\n' "$manifest_file" >&2
        exit 1
    fi
}

main() {
    local command="${1:-check}"

    load_manifest

    case "$command" in
        list-imported-roots)
            print_roots "${imported_roots[@]}"
            ;;
        list-z47-roots)
            print_roots "${z47_roots[@]}"
            ;;
        check)
            validate_manifest_coverage
            check_added_imported_paths
            printf 'Tracked source ownership roots: z47=%d imported=%d approved-imported-additions=%d\n' \
                "${#z47_roots[@]}" \
                "${#imported_roots[@]}" \
                "${#approved_imported_additions[@]}"
            ;;
        *)
            printf 'unknown command: %s\n' "$command" >&2
            exit 1
            ;;
    esac
}

main "$@"