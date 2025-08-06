#!/bin/bash
set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/notem/config"
DEFAULT_CONFIG_FILE="${HOME}/.notemrc"

NOTES_ROOT="${NOTES_ROOT:-$HOME/notes}"
REGULAR_NOTES_DIR=""
TEMPLATES_DIR="${TEMPLATES_DIR:-$HOME/.templates}"


create_default_config() {
    local config_file="$1"
    local config_dir
    config_dir=$(dirname "$config_file")

    mkdir -p "$config_dir"

    cat > "$config_file" << EOF
# Notem configuration file
# Created on $(date -u "+%Y-%m-%d %H:%M:S") UTC
# Change these values to alter the default behavior of notem

# Root directory for all notes
NOTES_ROOT=${HOME}/notes

# Directory for newly created (non-daily) notes
# If not set, defaults to NOTES_ROOT
REGULAR_NOTES_DIR=${NOTES_ROOT}

# Directory containing note templates
TEMPLATES_DIR=${HOME}/.templates
EOF

    echo "Created default configuration file at: $config_file"
}

load_config() {
    local config_file=""

    if [ -f "${CONFIG_FILE}" ]; then
        config_file="${CONFIG_FILE}"
    elif [ -f "${DEFAULT_CONFIG_FILE}" ]; then
        config_file="${DEFAULT_CONFIG_FILE}"
    else
        create_default_config "${DEFAULT_CONFIG_FILE}"
        config_file="${DEFAULT_CONFIG_FILE}"
    fi

    if [ -n "${config_file}" ]; then
        while IFS='=' read -r key value; do
            [[ "${key}" =~ ^[[:space:]]*# ]] && continue
            [[ -z "{key}" ]] && continue

            key=$(echo "${key}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "${value}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            case "${key}" in
                NOTES_ROOT)
                    NOTES_ROOT="${value}"
                    ;;
                REGULAR_NOTES_DIR)
                    REGULAR_NOTES_DIR="${value}"
                    ;;
                TEMLATES_DIR)
                    TEMPLATES_DIR="${value}"
                    ;;
            esac
        done < "${config_file}"
    fi
}

load_config

REGULAR_NOTES_DIR="${REGULAR_NOTES_DIR:-$NOTES_ROOT}"
DAILY_MODE=false
TEMPLATE_NAME=""
NOTE_NAME=""


if [ ! -d "${NOTES_ROOT}" ]; then
    echo "Error: NOTES_ROOT directory (${NOTES_ROOT}) does not exist" >&2
    exit 1
fi

usage() {
    echo "Usage: $0 [-d] [-t template_name] [-n note_name]" >&2
    echo "  -d: Create a daily note in dated directory structure" >&2
    echo "  -t: Specify a template to use" >&2
    echo "  -n: Specify note name (for non-daily notes)" >&2
    exit 1
}


while getopts "dt:n:" opt; do
    case "${opt}" in
        d)
            DAILY_MODE=true
            ;;
        t)
            TEMPLATE_NAME="${OPTARG}"
            ;;
        n)
            NOTE_NAME="${OPTARG}"
            ;;
        \?)
            echo "Invalid option: -${OPTARG}" >&2
            usage
            ;;
        :)
            echo "Option -${OPTARG} requires an argument." >&2
            usage
            ;;
    esac
done

if [ "${DAILY_MODE}" = true ]; then
    TODAY=$(date +"%Y-%m-%d")

    YEAR=$(date +"%Y")
    MONTH=$(date +"%m")
    DAY=$(date +"%d")

    FILE_PATH="${NOTES_ROOT}/daily/${YEAR}/${MONTH}/${DAY}/${TODAY}.md"
    if !  mkdir -p "${NOTES_ROOT}/daily/${YEAR}/${MONTH}/${DAY}"; then
        echo "Error: Failed to create directory structure" >&2
        exit 1
    fi
else
    if [ -z "${NOTE_NAME}" ]; then
        NOTE_NAME="note-$(date +"%Y%m%d-%H%M%S")"
    fi


    [[ "${NOTE_NAME}" != *.md  ]] && NOTE_NAME="${NOTE_NAME}.md"

    FILE_PATH="${REGULAR_NOTES_DIR}/${NOTE_NAME}"
    if ! mkdir -p "${REGULAR_NOTES_DIR}"; then
        echo "Error: Failed to create directory structure" >&2
        exit 1
    fi
fi

TEMPLATE_PATH="${TEMPLATES_DIR}/${TEMPLATE_NAME}.md"


if [ ! -f "${FILE_PATH}" ]; then
    if [ -f "${TEMPLATE_PATH}" ]; then
        sed -e "s/{{date}}/$(date -u "+%Y-%m-%d %H:%M:%S")/" \
            -e "s/{{author}}/${USER}/" \
            -e "s/{{year}}/$(date +"%Y")/" \
            -e "s/{{month}}/$(date +"%m")/" \
            -e "s/{{day}}/$(date +"%d")/" \
            -e "s/{{weekday}}/$(date +"%A")/" \
            "${TEMPLATE_PATH}" > "${FILE_PATH}"
    else
        if [ "${DAILY_MODE}" = true ] || [ -n "${TEMPLATE_PATH}" ]; then
            echo "---" > "${FILE_PATH}"
            echo "date: $(date -u "+%Y-%m-%d %H:%M:%S")" >> "${FILE_PATH}"
            echo "author: ${USER}" >> "${FILE_PATH}"
            echo "---" >> "${FILE_PATH}"
            echo "" >> "${FILE_PATH}"
        else
            touch "${FILE_PATH}"
        fi
    fi
fi

vim "${FILE_PATH}"
