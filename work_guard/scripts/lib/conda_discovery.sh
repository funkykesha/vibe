#!/usr/bin/env bash

workguard_find_conda() {
    local candidate
    for candidate in \
        "$HOME/miniforge3/bin/conda" \
        "$HOME/mambaforge/bin/conda" \
        "$HOME/miniconda3/bin/conda" \
        "$HOME/anaconda3/bin/conda" \
        "/opt/homebrew/Caskroom/miniforge/base/bin/conda" \
        "/opt/miniforge3/bin/conda"; do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

workguard_require_conda() {
    local conda_bin

    if ! conda_bin="$(workguard_find_conda)"; then
        echo "conda not found. Install Miniforge and retry." >&2
        echo "Suggested: brew install miniforge" >&2
        return 1
    fi

    echo "$conda_bin"
}
