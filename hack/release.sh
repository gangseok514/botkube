#!/bin/bash

set -e

version=$(cut -d'=' -f2- .release)
if [[ -z ${version} ]]; then
    echo "Invalid version set in .release";
    exit 1
fi

echo "Publishing release ${version}"

generate_changelog() {
    local version=$1

    # generate changelog from github
    github_changelog_generator infracloudio/botkube -t ${GITHUB_TOKEN} --future-release ${version} -o CHANGELOG.md
    sed -i '$d' CHANGELOG.md
}

update_chart_yamls() {
    local version=$1

    sed -i "s/version.*/version: ${version}/" helm/botkube/Chart.yaml
    sed -i "s/appVersion.*/appVersion: ${version}/" helm/botkube/Chart.yaml
    sed -i "s/\bimage: \"infracloud\/botkube.*\b/image: \"infracloud\/botkube:${version}/g" deploy-all-in-one.yaml
    sed -i "s/\bimage: \"infracloud\/botkube.*\b/image: \"infracloud\/botkube:${version}/g" deploy-all-in-one-tls.yaml

    oldVersion=$(echo $(awk '/BOTKUBE_VERSION/ {getline; print}' deploy-all-in-one.yaml))
    sed -i "s/\b${oldVersion}\b/value: ${version}/g" deploy-all-in-one.yaml
    sed -i "s/\b${oldVersion}\b/value: ${version}/g" deploy-all-in-one-tls.yaml
}

update_chart_yamls $version
generate_changelog $version
make release

echo "=========================== Done ============================="
echo "Congratulations!! Release ${version} tagged."
echo "Now go to github releases and publish the release."
echo "=============================================================="