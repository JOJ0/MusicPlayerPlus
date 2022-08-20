#!/bin/bash
PKG="musicplayerplus"
SRC_NAME="MusicPlayerPlus"
PKG_NAME="MusicPlayerPlus"
DESTDIR="usr"
SRC=${HOME}/src
SUDO=sudo
GCI=

[ -f "${SRC}/${SRC_NAME}/VERSION" ] || {
  [ -f "/builds/doctorfree/${SRC_NAME}/VERSION" ] || {
    echo "$SRC/$SRC_NAME/VERSION does not exist. Exiting."
    exit 1
  }
  SRC="/builds/doctorfree"
  SUDO=
  GCI=1
}

. "${SRC}/${SRC_NAME}/VERSION"
PKG_VER=${VERSION}
PKG_REL=${RELEASE}

umask 0022

# Subdirectory in which to create the distribution files
OUT_DIR="dist/${PKG_NAME}_${PKG_VER}"

[ -d "${SRC}/${SRC_NAME}" ] || {
    echo "$SRC/$SRC_NAME does not exist or is not a directory. Exiting."
    exit 1
}

cd "${SRC}/${SRC_NAME}"

# Build mpcplus
if [ -x scripts/build-mpcplus.sh ]
then
  scripts/build-mpcplus.sh -v
else
  cd mpcplus
  make clean
  make distclean
  [ -x ./configure ] || ./autogen.sh > /dev/null
  ./configure --prefix=/usr \
              --enable-outputs \
              --enable-clock \
              --enable-visualizer \
              --with-fftw \
              --with-taglib > configure$$.out
  make > make$$.out
  cd ..
fi

# Build mppcava
if [ -x scripts/build-mppcava.sh ]
then
  scripts/build-mppcava.sh
else
  cd mppcava
  make clean
  make distclean
  [ -x ./configure ] || ./autogen.sh > /dev/null
  ./configure --prefix=/usr > configure$$.out
  make > make$$.out
  cd ..
fi

# Build bliss-analyze
if [ -x scripts/build-bliss-analyze.sh ]
then
  scripts/build-bliss-analyze.sh
else
  PROJ=bliss-analyze
  [ -d ${PROJ} ] || git clone https://github.com/doctorfree/bliss-analyze
  [ -x ${PROJ}/target/release/bliss-analyze ] || {
    have_cargo=`type -p cargo`
    [ "${have_cargo}" ] || {
      echo "The cargo tool cannot be located."
      echo "Cargo is required to build bliss-analyze. Exiting."
      exit 1
    }
    cd ${PROJ}
    cargo build -r
    cd ..
  }
fi

# Build blissify
if [ -x scripts/build-blissify.sh ]
then
  scripts/build-blissify.sh
else
  PROJ=blissify
  [ -d ${PROJ} ] || git clone https://github.com/doctorfree/blissify
  [ -x ${PROJ}/target/release/blissify ] || {
    have_cargo=`type -p cargo`
    [ "${have_cargo}" ] || {
      echo "The cargo tool cannot be located."
      echo "Cargo is required to build blissify. Exiting."
      exit 1
    }
    cd ${PROJ}
    cargo build -r
    cd ..
  }
fi

# Build essentia
if [ -x scripts/build-essentia.sh ]
then
  scripts/build-essentia.sh
else
  cd essentia
  python3 waf configure --prefix=/usr --build-static --with-python --with-examples
  python3 waf
  cd ..
fi

${SUDO} rm -rf dist
mkdir dist

[ -d ${OUT_DIR} ] && rm -rf ${OUT_DIR}
mkdir ${OUT_DIR}

for dir in "${DESTDIR}" "${DESTDIR}/share" "${DESTDIR}/share/man" \
           "${DESTDIR}/share/applications" "${DESTDIR}/share/doc" \
           "${DESTDIR}/share/doc/${PKG}" "${DESTDIR}/share/doc/${PKG}/mpcplus" \
           "${DESTDIR}/share/consolefonts" "${DESTDIR}/share/${PKG}" \
           "${DESTDIR}/share/${PKG}/mpcplus" \
           "${DESTDIR}/share/doc/${PKG}/blissify" \
           "${DESTDIR}/share/doc/${PKG}/bliss-analyze"
do
    [ -d ${OUT_DIR}/${dir} ] || ${SUDO} mkdir ${OUT_DIR}/${dir}
    ${SUDO} chown root:root ${OUT_DIR}/${dir}
done

for dir in bin
do
    [ -d ${OUT_DIR}/${DESTDIR}/${dir} ] && ${SUDO} rm -rf ${OUT_DIR}/${DESTDIR}/${dir}
done

${SUDO} cp -a bin ${OUT_DIR}/${DESTDIR}/bin
${SUDO} cp mpcplus/src/mpcplus ${OUT_DIR}/${DESTDIR}/bin/mpcplus
${SUDO} cp mpcplus/extras/artist_to_albumartist \
           ${OUT_DIR}/${DESTDIR}/bin/artist_to_albumartist
${SUDO} cp mppcava/mppcava ${OUT_DIR}/${DESTDIR}/bin/mppcava
${SUDO} cp mppcava/mppcava.psf ${OUT_DIR}/${DESTDIR}/share/consolefonts
${SUDO} cp blissify/target/release/blissify ${OUT_DIR}/${DESTDIR}/bin
${SUDO} cp bliss-analyze/target/release/bliss-analyze ${OUT_DIR}/${DESTDIR}/bin
${SUDO} cp essentia/build/src/examples/essentia_streaming_extractor_music \
           ${OUT_DIR}/${DESTDIR}/bin
#${SUDO} cp essentia/build/src/examples/essentia_streaming_extractor_music_svm \
#           ${OUT_DIR}/${DESTDIR}/bin
# Install essentia
# if [ -x scripts/build-essentia.sh ]
# then
#   ${SUDO} scripts/build-essentia.sh -i -d "${SRC}/${SRC_NAME}/${OUT_DIR}"
# else
#   cd essentia
#   ${SUDO} python3 waf install --destdir="${SRC}/${SRC_NAME}/${OUT_DIR}"
#   cd ..
# fi

${SUDO} cp *.desktop "${OUT_DIR}/${DESTDIR}/share/applications"
${SUDO} cp copyright ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}
${SUDO} cp LICENSE ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}
${SUDO} cp NOTICE ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}
${SUDO} cp CHANGELOG.md ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}
${SUDO} cp README.md ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}
${SUDO} pandoc -f gfm README.md | ${SUDO} tee ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/README.html > /dev/null
${SUDO} gzip -9 ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/CHANGELOG.md

${SUDO} cp mpcplus/AUTHORS ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/mpcplus
${SUDO} cp mpcplus/COPYING ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/mpcplus
${SUDO} cp mpcplus/CHANGELOG.md ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/mpcplus
${SUDO} cp mpcplus/README.md ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/mpcplus

${SUDO} cp blissify/CHANGELOG.md ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/blissify
${SUDO} cp blissify/README.md ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/blissify

${SUDO} cp bliss-analyze/ChangeLog ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/bliss-analyze
${SUDO} cp bliss-analyze/LICENSE ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/bliss-analyze
${SUDO} cp bliss-analyze/README.md ${OUT_DIR}/${DESTDIR}/share/doc/${PKG}/bliss-analyze

${SUDO} cp asound.conf.tmpl ${OUT_DIR}/${DESTDIR}/share/${PKG}
${SUDO} cp mpcplus/doc/config ${OUT_DIR}/${DESTDIR}/share/${PKG}/mpcplus
${SUDO} cp mpcplus/doc/bindings ${OUT_DIR}/${DESTDIR}/share/${PKG}/mpcplus
${SUDO} cp config/config-art.conf ${OUT_DIR}/${DESTDIR}/share/${PKG}/mpcplus
${SUDO} cp config/default_cover.png ${OUT_DIR}/${DESTDIR}/share/${PKG}/mpcplus
${SUDO} cp config/fzmp.conf ${OUT_DIR}/${DESTDIR}/share/${PKG}/mpcplus
${SUDO} cp share/mpcplus-cheat-sheet.txt ${OUT_DIR}/${DESTDIR}/share/${PKG}/mpcplus
${SUDO} cp share/mpcplus-cheat-sheet.md ${OUT_DIR}/${DESTDIR}/share/${PKG}/mpcplus

${SUDO} cp -a share/scripts ${OUT_DIR}/${DESTDIR}/share/${PKG}/scripts
${SUDO} cp -a share/svm_models ${OUT_DIR}/${DESTDIR}/share/${PKG}/svm_models
${SUDO} cp -a share/calliope ${OUT_DIR}/${DESTDIR}/share/${PKG}/calliope

${SUDO} cp config/xterm-24bit.src ${OUT_DIR}/${DESTDIR}/share/${PKG}
${SUDO} cp config/tmux.conf ${OUT_DIR}/${DESTDIR}/share/${PKG}

${SUDO} cp -a config/beets "${OUT_DIR}/${DESTDIR}/share/${PKG}/beets"
${SUDO} cp -a beets "${OUT_DIR}/${DESTDIR}/share/${PKG}/beets/plugins"
${SUDO} cp config/calliope/* "${OUT_DIR}/${DESTDIR}/share/${PKG}/calliope"
${SUDO} cp -a config/mopidy "${OUT_DIR}/${DESTDIR}/share/${PKG}/mopidy"
${SUDO} cp -a config/mpd "${OUT_DIR}/${DESTDIR}/share/${PKG}/mpd"
${SUDO} cp -a config/mppcava "${OUT_DIR}/${DESTDIR}/share/${PKG}/mppcava"
${SUDO} cp mppcava/example_files/config ${OUT_DIR}/${DESTDIR}/share/${PKG}/mppcava/template.conf
${SUDO} cp -a config/navidrome "${OUT_DIR}/${DESTDIR}/share/${PKG}/navidrome"
${SUDO} cp -a config/tmuxp ${OUT_DIR}/${DESTDIR}/share/${PKG}/tmuxp
${SUDO} cp -a config/yt-dlp "${OUT_DIR}/${DESTDIR}/share/${PKG}/yt-dlp"
${SUDO} cp -a music "${OUT_DIR}/${DESTDIR}/share/${PKG}/music"

${SUDO} cp -a man/man1 ${OUT_DIR}/${DESTDIR}/share/man/man1
${SUDO} cp -a man/man5 ${OUT_DIR}/${DESTDIR}/share/man/man5
${SUDO} cp -a share/menu "${OUT_DIR}/${DESTDIR}/share/menu"

[ -f .gitignore ] && {
    while read ignore
    do
        ${SUDO} rm -f ${OUT_DIR}/${DESTDIR}/${ignore}
    done < .gitignore
}

${SUDO} chmod 644 ${OUT_DIR}/${DESTDIR}/share/man/*/*
${SUDO} chmod 644 ${OUT_DIR}/${DESTDIR}/share/menu/*
${SUDO} chmod 755 ${OUT_DIR}/${DESTDIR}/bin/* \
                  ${OUT_DIR}/${DESTDIR}/bin \
                  ${OUT_DIR}/${DESTDIR}/share/man \
                  ${OUT_DIR}/${DESTDIR}/share/man/* \
                  ${OUT_DIR}/${DESTDIR}/share/${PKG}/scripts/*
${SUDO} chown -R root:root ${OUT_DIR}/${DESTDIR}

echo "Building ${PKG_NAME}_${PKG_VER} rpm package"

[ -d pkg/rpm ] && cp -a pkg/rpm ${OUT_DIR}/rpm
[ -d ${OUT_DIR}/rpm ] || mkdir ${OUT_DIR}/rpm

have_rpm=`type -p rpmbuild`
[ "${have_rpm}" ] || {
  have_yum=`type -p yum`
  if [ "${have_yum}" ]
  then
    ${SUDO} yum install rpm-build
  else
    ${SUDO} apt-get update
    export DEBIAN_FRONTEND=noninteractive
    ${SUDO} ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
    ${SUDO} apt-get install rpm -y
    ${SUDO} dpkg-reconfigure --frontend noninteractive tzdata
  fi
}

rpmbuild -ba --build-in-place \
   --define "_topdir ${OUT_DIR}" \
   --define "_sourcedir ${OUT_DIR}" \
   --define "_version ${PKG_VER}" \
   --define "_release ${PKG_REL}" \
   --buildroot ${SRC}/${SRC_NAME}/${OUT_DIR}/BUILDROOT \
   ${OUT_DIR}/rpm/${PKG_NAME}.spec

# Rename RPMs if necessary
for rpmfile in ${OUT_DIR}/RPMS/*/*.rpm
do
  [ "${rpmfile}" == "${OUT_DIR}/RPMS/*/*.rpm" ] && continue
  rpmbas=`basename ${rpmfile}`
  rpmdir=`dirname ${rpmfile}`
  newnam=`echo ${rpmbas} | sed -e "s/${PKG_NAME}-${PKG_VER}-${PKG_REL}/${PKG_NAME}_${PKG_VER}-${PKG_REL}/"`
  [ "${rpmbas}" == "${newnam}" ] && continue
  mv ${rpmdir}/${rpmbas} ${rpmdir}/${newnam}
done

${SUDO} cp ${OUT_DIR}/RPMS/*/*.rpm dist

[ "${GCI}" ] || {
    [ -d releases ] || mkdir releases
    [ -d releases/${PKG_VER} ] || mkdir releases/${PKG_VER}
    ${SUDO} cp ${OUT_DIR}/RPMS/*/*.rpm releases/${PKG_VER}
}
