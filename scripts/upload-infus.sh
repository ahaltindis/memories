# usage from parent memories directory
# ./scripts/upload-infus.sh          - builds and uploads to infus
# ./scripts/upload-infus.sh last     - just uploads last tar to infus
# ./scripts/upload-infus.sh restore  - restores upstream in infus
#
set -e

echo $1

ssh -t ahmet@infus.home 'sudo --validate'
if [ "${1}" != "restore" ] && [ "${1}" != "last" ]; then
    echo "build"
    make dev-setup
    make build-js-production

    sh scripts/bundle.sh
fi

if [ "${1}" != "restore" ]; then
    scp memories.tar.gz ahmet@infus.home:/home/ahmet/memories_aha.tar.gz
fi

ssh -t ahmet@infus.home 'sudo bash -s' < scripts/run-in-infus.sh $1

