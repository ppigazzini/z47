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

list_index_top_level_roots() {
    git ls-files | awk -F/ '{print $1}' | sort -u
}

# A z47-owned root must not be gitignored. This is not hypothetical: upstream's
# .gitignore ignores a root `/build`, `.gitignore` is hand-reconciled on every
# resync, and z47 owns `build/`, `src/`, `docs/` and `bridge/`. The z47 section
# carries `!/build/`-style negations, but gitignore resolves by LAST MATCH, so that
# protection holds only while the imported block stays above the z47 section. An
# import that lands the other way round would not untrack anything -- ignore rules
# do not untrack -- it would silently stop NEW owner files from being added, which
# is the kind of failure that shows up as a mystery missing file weeks later.
# --no-index is required: check-ignore hides tracked files by default, which would
# make this pass for exactly the roots it is meant to protect.
require_unignored_root() {
    local root="$1"

    if git check-ignore --no-index -q -- "$root"; then
        printf 'z47-owned root is gitignored: %s\n' "$root" >&2
        printf 'A re-imported upstream .gitignore rule is shadowing it. The z47 negations\n' >&2
        printf '(!/build/, !/src/, !/docs/, !/bridge/) must stay BELOW the imported block.\n' >&2
        exit 1
    fi
}

validate_manifest_coverage() {
    local mode="${1:-head}"
    declare -A classified=()
    declare -A observed=()
    local root

    case "$mode" in
        head)
            while IFS= read -r root; do
                [[ -z "$root" ]] && continue
                observed[$root]=1
            done < <(git ls-tree --name-only HEAD | sort)
            ;;
        worktree)
            while IFS= read -r root; do
                [[ -z "$root" ]] && continue
                observed[$root]=1
            done < <(list_index_top_level_roots)
            ;;
        *)
            printf 'Unknown manifest coverage mode: %s\n' "$mode" >&2
            exit 1
            ;;
    esac

    for root in "${z47_roots[@]}"; do
        require_unignored_root "$root"
    done

    for root in "${z47_roots[@]}" "${imported_roots[@]}"; do
        if [[ -n "${classified[$root]+x}" ]]; then
            printf 'Duplicate root classification in %s: %s\n' "$manifest_file" "$root" >&2
            exit 1
        fi
        classified[$root]=1
        case "$mode" in
            head)
                require_tracked_root "$root"
                ;;
            worktree)
                if [[ -z "${observed[$root]+x}" ]]; then
                    printf 'Manifest entry is not present in the current tracked worktree: %s\n' "$root" >&2
                    exit 1
                fi
                ;;
        esac
    done

    local missing=0
    for root in "${!observed[@]}"; do
        if [[ -z "${classified[$root]+x}" ]]; then
            printf 'Tracked top-level path is missing from %s: %s\n' "$manifest_file" "$root" >&2
            missing=1
        fi
    done

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

    # Compare the pin's ROOT tree against the imported SUBTREE, not HEAD limited by
    # a pathspec. The imported tree is mounted under UPSTREAM_ROOT, so every
    # imported file has a repo path that differs from its path in the pin. A
    # pathspec-limited `git diff base..HEAD -- upstream` cannot pair them: the
    # rename sources (src/..., dep/..., docs/...) fall outside the pathspec, so
    # rename detection is starved and all ~1200 imported files read as ADDED.
    # Diffing tree-to-tree lines the two spellings up and yields upstream-relative
    # paths -- which is also what the approved-additions list records, for the same
    # reason every other ledger does (see upstream_paths.py).
    # The diff is CAPTURED, not piped straight into mapfile. `mapfile < <(cmd)`
    # runs cmd in a subshell whose failure `set -e` never sees, so a diff that
    # cannot run at all -- a mistyped UPSTREAM_ROOT makes `HEAD:<root>` fatal --
    # would hand back an empty list and this gate would report a clean tree. A
    # guard that passes because it measured NOTHING is worse than no guard, so an
    # unreadable input is fatal here.
    local diff_output=""
    local diff_status=0
    if [[ "$UPSTREAM_ROOT" == "." ]]; then
        diff_output="$(git diff --name-only --diff-filter=A "$diff_base"..HEAD -- "${imported_roots[@]}")" || diff_status=$?
    else
        diff_output="$(git diff --name-only --diff-filter=A "$diff_base" "HEAD:$UPSTREAM_ROOT")" || diff_status=$?
    fi

    if [[ "$diff_status" -ne 0 ]]; then
        printf 'Unable to diff the imported tree (UPSTREAM_ROOT=%s) against pinned %s.\n' \
            "$UPSTREAM_ROOT" \
            "$UPSTREAM_COMMIT" >&2
        printf 'Refusing to report a clean tree from a diff that did not run.\n' >&2
        exit 1
    fi

    local added_paths=()
    if [[ -n "$diff_output" ]]; then
        mapfile -t added_paths <<< "$diff_output"
    fi

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
            validate_manifest_coverage head
            check_added_imported_paths
            printf 'Tracked source ownership roots: z47=%d imported=%d approved-imported-additions=%d\n' \
                "${#z47_roots[@]}" \
                "${#imported_roots[@]}" \
                "${#approved_imported_additions[@]}"
            ;;
        check-worktree)
            validate_manifest_coverage worktree
            printf 'Tracked source ownership roots (worktree): z47=%d imported=%d approved-imported-additions=%d\n' \
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
