set -e

CUSTOM_APPS="/mnt/nvme/docker/volumes/nextcloud-bare_nextcloud/_data/custom_apps"
MEMORIES="${CUSTOM_APPS}/memories"
AHA_MARKER="${MEMORIES}/appinfo/.aha"

UP_BACKUP="memories_upstream.tar.gz"
AHA_PKG="/home/ahmet/memories_aha.tar.gz"

cd "${CUSTOM_APPS}"

if [ "${1}" == "restore" ]; then
    echo -e "\n> restoring upstream package"
    if [ -f "${UP_BACKUP}" ]; then
        echo "deleting ${MEMORIES}"
        rm -rf "${MEMORIES}"
        echo "extracting backup ${UP_BACKUP}"
        tar -xzvf "${UP_BACKUP}"
        echo -e "\ndone!"
        exit 0
    else
        echo -e "\nERROR - couldn't find ${UP_BACKUP}"
        exit 1
    fi
fi

if [ -f "${AHA_MARKER}" ]; then
    echo "! currently aha package is running"
else
    echo "! currently upstream package is running"
    # backup
    tar -czvf "${UP_BACKUP}" memories
fi

echo "deleting ${MEMORIES}"
rm -rf "${MEMORIES}"

echo "extracting new pkg ${AHA_PKG}"
tar -xzvf "${AHA_PKG}"

echo "set owners to www-data:www-data"
chown -R www-data:www-data "${MEMORIES}"

echo -e "\ndone!"

