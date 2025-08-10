#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/notem/config"
DEFAULT_CONFIG_FILE="${HOME}/.notemrc"

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
# Relative to NOTES_ROOT (ex: test = NOTES_ROOT/test)
# If not set, defaults to NOTES_ROOT
#REGULAR_NOTES_DIR=other

# Directory containing note templates
TEMPLATES_DIR=${HOME}/.templates

# Set your desired text editor (overrides $EDITOR env variable)
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
            [[ -z "${key}" ]] && continue

            key=$(echo "${key}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "${value}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            case "${key}" in
                NOTES_ROOT)
                    NOTES_ROOT="${value}"
                    ;;
                REGULAR_NOTES_DIR)
                    REGULAR_NOTES_DIR="${value}"
                    ;;
                TEMPLATES_DIR)
                    TEMPLATES_DIR="${value}"
                    ;;
                EDITOR)
                    CONF_EDITOR="${value}"
                    ;;
            esac
        done < "${config_file}"
    fi
}

load_config

NOTES_ROOT="${NOTES_ROOT:-$HOME/notes}"
TEMPLATES_DIR="${TEMPLATES_DIR:-$HOME/.templates}"
REGULAR_NOTES_DIR="${REGULAR_NOTES_DIR:-""}"
CONF_EDITOR="${CONF_EDITOR:-""}"
DAILY_MODE=false
TEMPLATE_NAME=""
NOTE_NAME=""
OPTIONAL_LOCATION=""

CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
CURRENT_TIMEZONE=$(date "+%z")
TODAY=$(date +"%Y-%m-%d")
YEAR=$(date +"%Y")
MONTH=$(date +"%m")
DAY=$(date +"%d")

HMS=$(date +"%H:%M:%S")
WEEKDAY=$(date +"%A")

CURRENT_USER=$USER
ENV_EDITOR=$EDITOR

if ! mkdir -p "${NOTES_ROOT}"; then
    echo "Error: failed to create directory structure ${NOTES_ROOT}" >&2
    exit 1
fi

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

while getopts "dt:n:l:" opt; do
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
        l)
            OPTIONAL_LOCATION="${OPTARG}"
            ;;
        \?)
            echo "Invalid option: -${opt}" >&2
            usage
            ;;
        :)
            echo "Option -${OPTARG} requires an argument." >&2
            usage
            ;;
    esac
done

if [ "${DAILY_MODE}" = true ]; then

    FILE_PATH="${NOTES_ROOT}/daily/${YEAR}/${MONTH}/daily-${TODAY}.md"
    if !  mkdir -p "${NOTES_ROOT}/daily/${YEAR}/${MONTH}"; then
        echo "Error: Failed to create directory structure" >&2
        exit 1
    fi
else
    if [ -z "${NOTE_NAME}" ]; then
        NOTE_NAME="note-$(date +"%Y%m%d-%H%M%S")"
    fi

    [[ "${NOTE_NAME}" != *.md  ]] && NOTE_NAME="${NOTE_NAME}.md"
    
    if [ -z "${OPTIONAL_LOCATION}" ]; then
        if [ -z "${REGULAR_NOTES_DIR}" ]; then
            FILE_PATH="${NOTES_ROOT}/${NOTE_NAME}"
        else

            FILE_PATH="${NOTES_ROOT}/${REGULAR_NOTES_DIR}/${NOTE_NAME}"
            if ! mkdir -p "${NOTES_ROOT}/${REGULAR_NOTES_DIR}"; then
                echo "Error: Failed to create directory structure" >&2
                exit 1
            fi
        fi
    else
       FILE_PATH="${OPTIONAL_LOCATION}/${NOTE_NAME}" 
    fi

fi

TEMPLATE_PATH="${TEMPLATES_DIR}/${TEMPLATE_NAME}.md"

if [ ! -f "${FILE_PATH}" ]; then

	if [ -n "${TEMPLATE_NAME}" ]; then
		if [ ! -f "${TEMPLATE_PATH}" ]; then
			echo "Error: Template '${TEMPLATE_NAME}' not found at '${TEMPLATE_PATH}'" >&2
			echo "Available templates in ${TEMPLATES_DIR}:" >&2
			ls -1 "${TEMPLATES_DIR}"/*.md 2>/dev/null || echo "No templates found" >&2
			exit 1
		
	    elif [ -f "${TEMPLATE_PATH}" ]; then
            sed -e "s/{{date}}/${TODAY}/" \
                -e "s/{{author}}/${CURRENT_USER}/" \
                -e "s/{{year}}/${YEAR}/" \
                -e "s/{{month}}/${MONTH}/" \
                -e "s/{{day}}/${DAY}/" \
                -e "s/{{weekday}}/${WEEKDAY}/" \
                "${TEMPLATE_PATH}" > "${FILE_PATH}"
        fi
    else
        echo "---" > "${FILE_PATH}"
        echo "date: ${CURRENT_TIME}" >> "${FILE_PATH}"
        echo "timezone: ${CURRENT_TIMEZONE}" >> "${FILE_PATH}"
        echo "author: ${USER}" >> "${FILE_PATH}"
        echo "---" >> "${FILE_PATH}"
        echo "" >> "${FILE_PATH}"
    fi
fi

if [[ -z "${CONF_EDITOR}" ]]; then
    if [[ -z "${ENV_EDITOR}" ]]; then
        nano "${FILE_PATH}"
    else
        "${ENV_EDITOR}" "${FILE_PATH}"
    fi
else
 "${CONF_EDITOR}" "${FILE_PATH}"
fi
