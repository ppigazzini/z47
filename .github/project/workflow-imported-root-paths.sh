#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
pin_file="$repo_root/.github/project/upstream-pin.env"

generated_artifact_paths=(
    "src/generated/softmenuCatalogs.h"
    "src/generated/constantPointers.c"
    "src/generated/constantPointers.h"
    "src/generated/constantPointers2.c"
    "src/generated/rasterFontsData.c"
    "res/testPgms/testPgms.bin"
)

host_package_common_paths=(
    "res/PROGRAMS"
    "res/STATE"
    "res/c47_pre.css"
    "res/C47.png"
    "res/C47short.png"
    "res/R47.png"
    "res/R47short.png"
    "res/fonts/C47__StandardFont.ttf"
)

workflow_direct_ref_pattern='docs/code/requirements\.txt|src/generated/|res/PROGRAMS|res/STATE|res/c47_pre\.css|res/C47\.png|res/C47short\.png|res/R47\.png|res/R47short\.png|res/c47\.xpm|res/fonts/C47__StandardFont\.ttf|res/testPgms/|res/tone|res/c47\.reg|res/r47\.reg'

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

load_upstream_root() {
    if [[ -n "${workflow_imported_root_loaded:-}" ]]; then
        return
    fi

    if [[ ! -f "$pin_file" ]]; then
        fail "missing upstream pin file: $pin_file"
    fi

    # shellcheck disable=SC1090
    . "$pin_file"
    if [[ -z "${UPSTREAM_ROOT:-}" ]]; then
        fail "missing UPSTREAM_ROOT in $pin_file"
    fi

    workflow_imported_root_loaded=1
}

resolve_repo_relative() {
    local relative_path="$1"

    load_upstream_root
    if [[ "$UPSTREAM_ROOT" == "." ]]; then
        printf '%s\n' "$relative_path"
    else
        printf '%s/%s\n' "$UPSTREAM_ROOT" "$relative_path"
    fi
}

copy_required_relative() {
    copy_required_relative_as "$1" "$1" "$2"
}

copy_required_relative_as() {
    local relative_path="$1"
    local target_relative_path="$2"
    local stage_dir="$3"
    local source_path target_path

    source_path="$repo_root/$(resolve_repo_relative "$relative_path")"
    target_path="$stage_dir/$target_relative_path"

    if [[ ! -e "$source_path" ]]; then
        fail "missing required imported-root path: $source_path"
    fi

    rm -rf "$target_path"
    mkdir -p "$(dirname -- "$target_path")"
    cp -a "$source_path" "$target_path"
}

copy_optional_relative() {
    copy_optional_relative_as "$1" "$1" "$2"
}

copy_optional_relative_as() {
    local relative_path="$1"
    local target_relative_path="$2"
    local stage_dir="$3"
    local source_path target_path

    source_path="$repo_root/$(resolve_repo_relative "$relative_path")"
    target_path="$stage_dir/$target_relative_path"
    if [[ ! -e "$source_path" ]]; then
        return
    fi

    rm -rf "$target_path"
    mkdir -p "$(dirname -- "$target_path")"
    cp -a "$source_path" "$target_path"
}

copy_directory_contents() {
    local relative_dir="$1"
    local stage_dir="$2"
    local source_dir target_dir

    source_dir="$repo_root/$(resolve_repo_relative "$relative_dir")"
    target_dir="$stage_dir/$relative_dir"

    if [[ ! -d "$source_dir" ]]; then
        fail "missing required imported-root directory: $source_dir"
    fi

    rm -rf "$target_dir"
    mkdir -p "$target_dir"
    cp -a "$source_dir/." "$target_dir/"
}

list_docs_requirements() {
    resolve_repo_relative "docs/code/requirements.txt"
}

list_generated_artifacts() {
    local relative_path

    for relative_path in "${generated_artifact_paths[@]}"; do
        resolve_repo_relative "$relative_path"
    done
}

stage_host_package_common() {
    local stage_dir="$1"

    mkdir -p "$stage_dir"
    copy_required_relative "res/PROGRAMS" "$stage_dir"
    copy_required_relative "res/STATE" "$stage_dir"
    copy_required_relative "res/c47_pre.css" "$stage_dir"
    copy_required_relative "res/C47.png" "$stage_dir"
    copy_required_relative "res/C47short.png" "$stage_dir"
    copy_required_relative "res/R47.png" "$stage_dir"
    copy_required_relative "res/R47short.png" "$stage_dir"
    copy_required_relative_as "res/fonts/C47__StandardFont.ttf" "C47__StandardFont.ttf" "$stage_dir"
}

stage_host_package_windows() {
    local stage_dir="$1"

    mkdir -p "$stage_dir"
    copy_required_relative "res/testPgms/testPgms.bin" "$stage_dir"
    copy_optional_relative "res/testPgms/testPgms.txt" "$stage_dir"
    copy_directory_contents "res/tone" "$stage_dir"
    copy_required_relative_as "res/c47.reg" "c47.reg" "$stage_dir"
    copy_required_relative_as "res/r47.reg" "r47.reg" "$stage_dir"
}

validate_static_path_lists() {
    local expected_count actual_count

    expected_count=8
    actual_count="${#host_package_common_paths[@]}"
    if [[ "$actual_count" -ne "$expected_count" ]]; then
        fail "host_package_common_paths drifted from the staged common package mapping"
    fi
}

check_workflow_literals() {
    local matches

    validate_static_path_lists

    matches="$(grep -RInE --include='*.yml' "$workflow_direct_ref_pattern" "$repo_root/.github/workflows" || true)"
    if [[ -n "$matches" ]]; then
        printf 'Direct imported-root workflow references remain outside %s:\n' "$0" >&2
        printf '%s\n' "$matches" >&2
        exit 1
    fi

    printf 'Workflow imported-root direct references: 0\n'
}

usage() {
    cat <<'EOF'
usage:
  workflow-imported-root-paths.sh docs-requirements
  workflow-imported-root-paths.sh generated-artifacts
  workflow-imported-root-paths.sh stage-host-package-common <stage-dir>
  workflow-imported-root-paths.sh stage-host-package-windows <stage-dir>
  workflow-imported-root-paths.sh check-workflow
EOF
}

main() {
    local command="${1:-}"

    case "$command" in
        docs-requirements)
            list_docs_requirements
            ;;
        generated-artifacts)
            list_generated_artifacts
            ;;
        stage-host-package-common)
            [[ $# -eq 2 ]] || fail "stage-host-package-common requires <stage-dir>"
            stage_host_package_common "$2"
            ;;
        stage-host-package-windows)
            [[ $# -eq 2 ]] || fail "stage-host-package-windows requires <stage-dir>"
            stage_host_package_windows "$2"
            ;;
        check-workflow)
            check_workflow_literals
            ;;
        *)
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"