#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
manifest_file="$repo_root/.github/project/source-ownership.txt"
guard_script="$repo_root/.github/project/check-source-ownership.sh"
pilot_layout_name="nested-upstream-pilot"

usage() {
    cat <<'EOF'
usage:
    nested-upstream-pilot.sh prepare <worktree-path> [repo-relative-path ...]
  nested-upstream-pilot.sh report <worktree-path>
  nested-upstream-pilot.sh cleanup <worktree-path>

prepare creates a detached linked worktree at <worktree-path>, moves every
tracked imported-upstream root under upstream/, and rewrites the pinned layout
metadata for the pilot candidate. Additional repo-relative paths are copied
from the current working tree into the pilot before the layout rewrite so the
candidate can include uncommitted local overlay changes.

report prints the current pilot metrics for a prepared worktree.

cleanup removes a pilot worktree with git worktree remove --force.
EOF
}

trim_line() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s\n' "$value"
}

list_approved_imported_additions() {
    local section=""
    local raw_line line

    while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
        line="${raw_line%%#*}"
        line="$(trim_line "$line")"
        [[ -z "$line" ]] && continue

        case "$line" in
            "[approved-z47-additions-under-imported]")
                section="approved"
                continue
                ;;
            "["*)
                section=""
                continue
                ;;
        esac

        if [[ "$section" == "approved" ]]; then
            printf '%s\n' "$line"
        fi
    done < "$manifest_file"
}

rewrite_pin_file() {
    local worktree_path="$1"
    local pin_file="$worktree_path/.github/project/upstream-pin.env"
    local tmp_file="$pin_file.tmp"

    : > "$tmp_file"
    while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
        case "$raw_line" in
            UPSTREAM_ROOT=*)
                printf 'UPSTREAM_ROOT=upstream\n' >> "$tmp_file"
                ;;
            UPSTREAM_IMPORT_LAYOUT=*)
                printf 'UPSTREAM_IMPORT_LAYOUT=%s\n' "$pilot_layout_name" >> "$tmp_file"
                ;;
            *)
                printf '%s\n' "$raw_line" >> "$tmp_file"
                ;;
        esac
    done < "$pin_file"

    mv "$tmp_file" "$pin_file"
}

rewrite_manifest() {
    local worktree_path="$1"
    local worktree_manifest="$worktree_path/.github/project/source-ownership.txt"
    local approved_additions=()

    mapfile -t approved_additions < <(list_approved_imported_additions)

    {
        printf '# z47 tracked source ownership manifest\n'
        printf '#\n'
        printf '# Entries are repo-root paths. Keep every tracked top-level path classified in\n'
        printf '# exactly one of the first two sections.\n\n'
        printf '[z47-owned]\n'
        bash "$guard_script" list-z47-roots
        printf '\n[imported-upstream]\n'
        printf 'upstream\n\n'
        printf '[approved-z47-additions-under-imported]\n'

        if [[ "${#approved_additions[@]}" -eq 0 ]]; then
            printf '# Keep this section empty unless a reviewed exception is required.\n'
        else
            local addition
            for addition in "${approved_additions[@]}"; do
                printf 'upstream/%s\n' "$addition"
            done
        fi
    } > "$worktree_manifest"
}

sync_local_paths_into_worktree() {
    local worktree_path="$1"
    shift
    local relative_path
    local source_path
    local destination_path

    for relative_path in "$@"; do
        source_path="$repo_root/$relative_path"
        destination_path="$worktree_path/$relative_path"

        if [[ ! -e "$source_path" ]]; then
            printf 'Requested working-tree overlay path does not exist: %s\n' "$relative_path" >&2
            exit 1
        fi

        rm -rf "$destination_path"
        mkdir -p "$(dirname -- "$destination_path")"
        cp -a "$source_path" "$destination_path"
    done
}

prepare_worktree() {
    local worktree_path="$1"
    shift
    local imported_roots=()
    local root

    if [[ -e "$worktree_path" ]]; then
        printf 'Pilot worktree path already exists: %s\n' "$worktree_path" >&2
        exit 1
    fi

    git -C "$repo_root" worktree add --detach "$worktree_path" HEAD

    if [[ "$#" -gt 0 ]]; then
        sync_local_paths_into_worktree "$worktree_path" "$@"
    fi

    mapfile -t imported_roots < <(bash "$guard_script" list-imported-roots)
    mkdir -p "$worktree_path/upstream"
    for root in "${imported_roots[@]}"; do
        git -C "$worktree_path" mv -- "$root" upstream/
    done

    rewrite_pin_file "$worktree_path"
    rewrite_manifest "$worktree_path"
}

count_git_grep_matches() {
    local worktree_path="$1"
    local pattern="$2"
    shift 2
    local output=""

    output="$(git -C "$worktree_path" grep -nE "$pattern" -- "$@" || true)"
    if [[ -z "$output" ]]; then
        printf '0\n'
        return
    fi

    printf '%s\n' "$output" | wc -l | tr -d ' '
    printf '\n'
}

report_worktree() {
    local worktree_path="$1"
    local changed_paths_total
    local renamed_paths_total
    local overlay_paths_changed
    local imported_roots_before
    local imported_roots_after
    local stale_workflow_repo_root_refs
    local stale_dist_repo_root_refs
    local layout_name
    local upstream_root

    if [[ ! -d "$worktree_path/.git" && ! -f "$worktree_path/.git" ]]; then
        printf 'Pilot worktree does not exist: %s\n' "$worktree_path" >&2
        exit 1
    fi

    changed_paths_total="$(git -C "$worktree_path" diff --name-only HEAD -- | wc -l | tr -d ' ')"
    renamed_paths_total="$(git -C "$worktree_path" diff --summary -M HEAD -- | grep -c '^ rename ' || true)"
    overlay_paths_changed="$(git -C "$worktree_path" diff --name-only HEAD -- .github CONTRIBUTING.md ZIG-README.md build.zig zig_bridge zig_build zig_docs zig_src | wc -l | tr -d ' ')"
    imported_roots_before="$(bash "$guard_script" list-imported-roots | wc -l | tr -d ' ')"
    imported_roots_after="$(cd "$worktree_path" && bash .github/project/check-source-ownership.sh list-imported-roots | paste -sd ',' -)"
    stale_workflow_repo_root_refs="$(count_git_grep_matches "$worktree_path" 'docs/code/|src/generated/|res/PROGRAMS|res/STATE|res/testPgms|res/fonts/|res/tone|res/keymaps/|res/dmcp5/|res/combo/' '.github/workflows/*.yml')"
    stale_dist_repo_root_refs="$(count_git_grep_matches "$worktree_path" 'REPO_ROOT / "res/' 'zig_build/zig_dist.py')"
    upstream_root="$(awk -F= '/^UPSTREAM_ROOT=/{print $2}' "$worktree_path/.github/project/upstream-pin.env")"
    layout_name="$(awk -F= '/^UPSTREAM_IMPORT_LAYOUT=/{print $2}' "$worktree_path/.github/project/upstream-pin.env")"

    cat <<EOF
worktree=$worktree_path
layout=$layout_name
upstream_root=$upstream_root
imported_roots_before=$imported_roots_before
imported_roots_after=$imported_roots_after
changed_paths_total=$changed_paths_total
renamed_paths_total=$renamed_paths_total
overlay_paths_changed=$overlay_paths_changed
stale_workflow_repo_root_refs=$stale_workflow_repo_root_refs
stale_zig_dist_repo_root_refs=$stale_dist_repo_root_refs
rollback=git -C $repo_root worktree remove --force $worktree_path
EOF
}

cleanup_worktree() {
    local worktree_path="$1"
    git -C "$repo_root" worktree remove --force "$worktree_path"
}

main() {
    local command="${1:-}"
    local worktree_path="${2:-}"

    if [[ -z "$command" || -z "$worktree_path" ]]; then
        usage >&2
        exit 1
    fi

    case "$command" in
        prepare)
            shift 2
            prepare_worktree "$worktree_path" "$@"
            report_worktree "$worktree_path"
            ;;
        report)
            report_worktree "$worktree_path"
            ;;
        cleanup)
            cleanup_worktree "$worktree_path"
            ;;
        *)
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"