#!/bin/bash

function getSessionForUser {
# check configuration

  if [ -z "${GITLAB_URL_PREFIX}" ]; then
    echo "** GITLAB_URL_PREFIX is missing."
    exit 1
  fi
  if [ -z "${GITLAB_API_VERSION}" ]; then
    echo "** GITLAB_API_VERSION is missing."
    exit 1
  fi
  if [ -z "${GITLAB_USER}" ]; then
    echo "** GITLAB_USER is missing."
    exit 1
  fi
  if [ -z "${GITLAB_PASSWORD}" ]; then
    echo "** GITLAB_PASSWORD is missing."
    exit 1
  fi

  local url="${GITLAB_URL_PREFIX}/api/${GITLAB_API_VERSION}/session"

  echo "# GitLab Session URL: ${url}" >&2

  curl --silent  --data "login=${GITLAB_USER}&password=${GITLAB_PASSWORD}" ${url} || exit 1
}

GITLAB_BASH_API_CONFIG=$(realpath $(dirname $(dirname $(realpath "$0")))/gitlab-bash-api-config-for-docker)
GITLAB_BASH_API_CONFIG_FOLDER="${GITLAB_BASH_API_CONFIG}/"
GENERATE_PRIVATE_TOKEN_FILE=${GITLAB_BASH_API_CONFIG_FOLDER}generate-private-token

echo "Look for configuration into '${GITLAB_BASH_API_CONFIG_FOLDER}'" >&2

if [ ! -d "${GITLAB_BASH_API_CONFIG_FOLDER}" ] ; then
  echo "*** Can not find configuration folder: '${GITLAB_BASH_API_CONFIG_FOLDER}'" >&2
  exit 1
fi

for file in $(find "${GITLAB_BASH_API_CONFIG_FOLDER}" -type f); do

  if [ "${file}" = "${GENERATE_PRIVATE_TOKEN_FILE}" ]; then
    echo "Skip '${file}'" >&2
  else
    echo "Use configuration in '${file}'" >&2

    source "${file}"
  fi
done

# gain a gitlab token for user
SESSION=$(getSessionForUser)
TOKEN=$(echo "${SESSION}" | jq --raw-output '. .private_token')

if [ -z "${TOKEN}" ]; then
  echo "*** Can not get tocken from GitLab..."
  exit 1
fi

echo "Create '${GENERATE_PRIVATE_TOKEN_FILE}'" >&2
echo "#!/bin/bash

GITLAB_PRIVATE_TOKEN=${TOKEN}
" >"${GENERATE_PRIVATE_TOKEN_FILE}"

echo "${SESSION}" | jq .