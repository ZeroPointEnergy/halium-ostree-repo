#
# Update ubports rootfs branch
#
usage(){
	echo './update-ubports-rootfs.sh "my commit message"'
}

UBPORTS_TAR='ubports-touch.rootfs-xenial-armhf.tar'
UBPORTS_SRC="https://ci.ubports.com/job/xenial-rootfs-armhf/lastSuccessfulBuild/artifact/out/${UBPORTS_TAR}.gz"
UBPORTS_TMP="tmp/${UBPORTS_TAR}"

OSTREE='ostree --repo=./repo'
UBPORTS_BRANCH='ubuntu-touch/xenial-armhf/daily'

COMMIT_MSG=$1
if [ -z "$COMMIT_MSG" ]
then
	echo 'Please provide a commit message'
	usage
	exit -1
fi

if [ -f $UBPORTS_TMP ]
then
	echo "Using existing rootfs tarball under ${UBPORTS_TMP}"
else
	echo 'Attempting to download new rootfs tarball'
	wget -O "${UBPORTS_TMP}.gz" $UBPORTS_SRC
	gunzip "${UBPORTS_TMP}.gz"
	# ostree can't handle device files
	tar --delete --file $UBPORTS_TMP dev/
fi

echo 'Merging halium overlay into root tarball'
OVERLAY_TMP='tmp/overlay-ubports.tar'
rm -f $OVERLAY_TMP
pushd overlays/ubports > /dev/null
	tar --create --file "../../${OVERLAY_TMP}" --owner root --group root .
popd > /dev/null
tar --concat --file $UBPORTS_TMP $OVERLAY_TMP

echo "commiting tarball to ostree branch ${UBPORTS_BRANCH}"
$OSTREE refs
$OSTREE commit --branch=$UBPORTS_BRANCH --subject="$COMMIT_MSG" --tree=tar=$UBPORTS_TMP --skip-if-unchanged
$OSTREE summary --update
