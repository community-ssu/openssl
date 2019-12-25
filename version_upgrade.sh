#!/bin/bash

EXACT_VERSION=$(sed -rn '/^[[:space:]]*dh_makeshlibs/s#.* (.+)-.*#\1#p' debian/rules)
NUMBER_VERSION=$(sed -r 's#[a-z]+$##' <<< ${EXACT_VERSION})

echo "Previous version: ${NUMBER_VERSION} (${EXACT_VERSION})"

if [ $# -ne 1 ]; then
	echo "Usage: ${0} new_version" >&2
	exit 1
fi

NEW_VERSION=${1}
NEW_NUMBER_VERSION=$(sed -r 's#[a-z]+$##' <<< ${NEW_VERSION})

if [ "${NEW_VERSION}" = "${NEW_NUMBER_VERSION}" ]; then
	# this will not work with the new versioning scheme, but that
	# needs more version number adaptions anyway
	echo "cannot split new version number: ${NEW_VERSION}" >&2
	exit 1
fi

if [ "${NEW_VERSION}" = "${EXACT_VERSION}" ]; then
	echo "Old and new versions are the same" >&2
	exit 1
fi

if [ "${NEW_NUMBER_VERSION}" != "${NUMBER_VERSION}" ]; then
	for i in debian/libssl${NUMBER_VERSION}.*; do
		git mv ${i} ${i/${NUMBER_VERSION}/${NEW_NUMBER_VERSION}}
	done
fi

sed -i "/^[[:space:]]*dh_makeshlibs/s#${EXACT_VERSION}#${NEW_VERSION}#" debian/rules
sed -i "s#${EXACT_VERSION}#${NEW_VERSION}#g" HOWTOBUILD
sed -i "s#${NUMBER_VERSION}#${NEW_NUMBER_VERSION}#g" -i $(find debian/ -maxdepth 1 -type f '!' -name changelog) HOWTOBUILD

sed "1i\\openssl (${NEW_VERSION}-1+maemo1+0osm2go0) unstable; urgency=low\n\n  * Latest upstream release.\n\n -- $(git config user.name) <$(git config user.email)>  $(date -R)\n" -i debian/changelog
