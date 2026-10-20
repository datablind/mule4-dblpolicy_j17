#!/usr/bin/env bash
#
# Builds the policy and publishes it to Anypoint Exchange (group/org id taken from pom.xml)
# using an Anypoint Connected App (client credentials).
#
# Usage:
#   export ANYPOINT_CLIENT_ID=...
#   export ANYPOINT_CLIENT_SECRET=...
#   export DBLREPO_USERNAME=<github user>      # needed to download com.ztensor:datacrypt-release
#   export DBLREPO_PASSWORD=<github token with read:packages>
#   export MULE_ENTREPO_USERNAME=<MuleSoft Enterprise repository (Nexus EE) username>
#   export MULE_ENTREPO_PASSWORD=<MuleSoft Enterprise repository (Nexus EE) password>
#   ./deploy-to-exchange.sh            # asks for confirmation before publishing
#   ./deploy-to-exchange.sh --yes      # no confirmation prompt
#   DRY_RUN=1 ./deploy-to-exchange.sh  # show what would run, publish nothing
#
# You can also paste the values below instead of exporting them, but do NOT commit
# the file with real secrets in it. Prefer environment variables.
#
# The Connected App needs these scopes on the target organization / business group:
#   Exchange Contributor  (publish the asset)
#   Exchange Viewer       (download the Mule plugins the build depends on)

set -euo pipefail
cd "$(dirname "$0")"

ANYPOINT_CLIENT_ID="${ANYPOINT_CLIENT_ID:-}"
ANYPOINT_CLIENT_SECRET="${ANYPOINT_CLIENT_SECRET:-}"
DBLREPO_USERNAME="${DBLREPO_USERNAME:-}"
DBLREPO_PASSWORD="${DBLREPO_PASSWORD:-}"
# REQUIRED: com.mulesoft.anypoint:mule-http-policy-transform-extension (and MuleSoft's patched Spring)
# are only available from the MuleSoft Enterprise repository, which uses its own customer credentials.
# These are NOT the Connected App credentials. CI uses the MULE_ENTREPO_USERNAME/PASSWORD secrets.
MULE_ENTREPO_USERNAME="${MULE_ENTREPO_USERNAME:-}"
MULE_ENTREPO_PASSWORD="${MULE_ENTREPO_PASSWORD:-}"

die() { echo "ERROR: $*" >&2; exit 1; }

[ -n "$ANYPOINT_CLIENT_ID" ]     || die "ANYPOINT_CLIENT_ID is not set"
[ -n "$ANYPOINT_CLIENT_SECRET" ] || die "ANYPOINT_CLIENT_SECRET is not set"
[ -n "$MULE_ENTREPO_USERNAME" ]  || die "MULE_ENTREPO_USERNAME is not set (MuleSoft Enterprise repository login; required, see comments at top)"
[ -n "$MULE_ENTREPO_PASSWORD" ]  || die "MULE_ENTREPO_PASSWORD is not set"
command -v mvn >/dev/null        || die "mvn not found on PATH"
if [ -z "$DBLREPO_USERNAME" ] || [ -z "$DBLREPO_PASSWORD" ]; then
  echo "WARNING: DBLREPO_USERNAME/DBLREPO_PASSWORD not set. The build only works if" >&2
  echo "         com.ztensor:datacrypt-release is already in ~/.m2." >&2
fi

# Secrets go to Maven through environment variables and a temporary settings file,
# never on the command line, so they do not show up in 'ps' output or logs.
# Connected App login for the Exchange Maven facade: user "~~~Client~~~", password "<id>~?~<secret>".
export ANYPOINT_MVN_USER='~~~Client~~~'
export ANYPOINT_MVN_PASS="${ANYPOINT_CLIENT_ID}~?~${ANYPOINT_CLIENT_SECRET}"
export DBLREPO_MVN_USER="${DBLREPO_USERNAME:-unused}"
export DBLREPO_MVN_PASS="${DBLREPO_PASSWORD:-unused}"
export MULEREPO_MVN_USER="${MULE_ENTREPO_USERNAME:-unused}"
export MULEREPO_MVN_PASS="${MULE_ENTREPO_PASSWORD:-unused}"

TMP_SETTINGS="$(mktemp "${TMPDIR:-/tmp}/exchange-settings.XXXXXX")"
trap 'rm -f "$TMP_SETTINGS"' EXIT
chmod 600 "$TMP_SETTINGS"

sed \
  -e 's/\${anypoint_username}/${env.ANYPOINT_MVN_USER}/g' \
  -e 's/\${anypoint_password}/${env.ANYPOINT_MVN_PASS}/g' \
  -e 's/\${dblrepo_username}/${env.DBLREPO_MVN_USER}/g' \
  -e 's/\${dblrepo_password}/${env.DBLREPO_MVN_PASS}/g' \
  -e 's/\${muleentrepo_username}/${env.MULEREPO_MVN_USER}/g' \
  -e 's/\${muleentrepo_password}/${env.MULEREPO_MVN_PASS}/g' \
  settings.xml > "$TMP_SETTINGS"

GROUP_ID="$(sed -n 's#^[[:space:]]*<groupId>\(.*\)</groupId>.*#\1#p' pom.xml | head -1)"
ARTIFACT_ID="$(sed -n 's#^[[:space:]]*<artifactId>\(.*\)</artifactId>.*#\1#p' pom.xml | head -1)"
VERSION="$(sed -n 's#^[[:space:]]*<version>\(.*\)</version>.*#\1#p' pom.xml | head -1)"

# pom.xml uploads ${project.artifactId}.yaml as the policy definition; fail early if it is missing
[ -f "${ARTIFACT_ID}.yaml" ] || die "${ARTIFACT_ID}.yaml not found. pom.xml deploys \${project.artifactId}.yaml, so the YAML file name must match the artifactId."

echo "About to publish to Anypoint Exchange:"
echo "  groupId (organization): $GROUP_ID"
echo "  assetId:                $ARTIFACT_ID"
echo "  version:                $VERSION"
echo

MVN_CMD=(mvn clean deploy -s "$TMP_SETTINGS" -DskipTests -Dmaven.javadoc.skip=true -Dmaven.install.skip=true)

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "DRY_RUN=1, would run: ${MVN_CMD[*]}"
  exit 0
fi

if [ "${1:-}" != "--yes" ]; then
  read -r -p "Publish this version now? Exchange does not allow re-publishing the same version. [y/N] " ans
  case "$ans" in y|Y|yes|YES) ;; *) echo "Aborted."; exit 1 ;; esac
fi

"${MVN_CMD[@]}"

echo
echo "Published ${GROUP_ID}:${ARTIFACT_ID}:${VERSION}."
echo "Next: Anypoint Platform > API Manager > your API > Policies > Apply New Policy > 'DataBlind'."
