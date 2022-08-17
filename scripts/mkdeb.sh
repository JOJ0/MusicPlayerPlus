#!/bin/bash
PKG="musicplayerplus"
SRC_NAME="MusicPlayerPlus"
PKG_NAME="MusicPlayerPlus"
DEBFULLNAME="Ronald Record"
DEBEMAIL="ronaldrecord@gmail.com"
DESTDIR="usr"
SRC=${HOME}/src
ARCH=amd64
SUDO=sudo
GCI=

dpkg=`type -p dpkg-deb`
[ "${dpkg}" ] || {
    echo "Debian packaging tools do not appear to be installed on this system"
    echo "Are you on the appropriate Linux system with packaging requirements ?"
    echo "Exiting"
    exit 1
}
dpkg_arch=`dpkg --print-architecture`
[ "${dpkg_arch}" == "${ARCH}" ] || ARCH=${dpkg_arch}

[ -f "${SRC}/${SRC_NAME}/VERSION" ] || {
  [ -f "/builds/doctorfree/${SRC_NAME}/VERSION" ] || {
    echo "$SRC/$SRC_NAME/VERSION does not exist. Exiting."
    exit 1
  }
  SRC="/builds/doctorfree"
  GCI=1
# SUDO=
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
cp -a pkg/debian ${OUT_DIR}/DEBIAN
chmod 755 ${OUT_DIR} ${OUT_DIR}/DEBIAN ${OUT_DIR}/DEBIAN/*

echo "Package: ${PKG}
Version: ${PKG_VER}-${PKG_REL}
Section: sound
Priority: optional
Architecture: ${ARCH}
Depends: libboost-all-dev (>= 1.71.0), libcurl4 (>= 7.68.0), libmpdclient2 (>= 2.9), libncursesw6 (>= 6), libreadline8 (>= 6.0), libtag1v5 (>= 1.11), libtinfo6 (>= 6), mpd (>= 0.21.20), gnome-terminal, tilix (>= 1.9.1), cool-retro-term (>= 1.1.1), tmux, ffmpeg, inotify-tools, figlet, fzf, mpc, python3-dev, python3-pip, mplayer, asciinema, libchromaprint-dev, dconf-cli, uuid-runtime, libeigen3-dev, libfftw3-dev, libsamplerate0, libiniparser-dev, libyaml-dev, libasound2, libpulse-dev, libcurl4-openssl-dev, libsqlite3-0 (>= 3.6.0), libavformat58 (>= 7:4.1), libavfilter7 (>= 7:4.0), libswresample3 (>= 7:4.0), libavcodec58 (>= 7:4.2), libswscale5 (>= 7:4.0), libavdevice58 (>= 7:4.0), libavutil56 (>= 7:4.0)
Maintainer: ${DEBFULLNAME} <${DEBEMAIL}>
Installed-Size: 203000
Build-Depends: debhelper (>= 11)
Provides: mpcplus-completion, mpd-client
Suggests: desktop-file-utils
Homepage: https://github.com/doctorfree/MusicPlayerPlus
Description: Music Player Plus
 ncurses-based client for the Music Player Daemon (MPD)
 mpcplus is almost an exact clone of ncmpc which is a text-mode client
 for MPD, the Music Player Daemon. It provides a keyboard oriented and
 consistent interface to MPD and contains some new features ncmpc
 doesn't have. It's also been rewritten from scratch in C++.
 .
 New features include:
  - tag editor;
  - playlists editor;
  - easy to use search screen;
  - media library screen;
  - lyrics screen;
  - possibility of going to any position in currently playing track
    without rewinding/fastforwarding;
  - multi colored main window (if you want);
  - songs can be added to playlist more than once;
  - a lot of minor useful functions." > ${OUT_DIR}/DEBIAN/control

chmod 644 ${OUT_DIR}/DEBIAN/control

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
${SUDO} cp mppcava/mppcava ${OUT_DIR}/${DESTDIR}/bin/mppcava
${SUDO} cp mppcava/mppcava.psf ${OUT_DIR}/${DESTDIR}/share/consolefonts
[ -f blissify/target/release/blissify ] && {
  ${SUDO} cp blissify/target/release/blissify ${OUT_DIR}/${DESTDIR}/bin
}
[ -f bliss-analyze/target/release/bliss-analyze ] && {
  ${SUDO} cp bliss-analyze/target/release/bliss-analyze ${OUT_DIR}/${DESTDIR}/bin
}
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
${SUDO} cp -a config/mpd "${OUT_DIR}/${DESTDIR}/share/${PKG}/mpd"
${SUDO} cp -a config/mppcava "${OUT_DIR}/${DESTDIR}/share/${PKG}/mppcava"
${SUDO} cp mppcava/example_files/config ${OUT_DIR}/${DESTDIR}/share/${PKG}/mppcava/template.conf
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

cd dist
echo "Building ${PKG_NAME}_${PKG_VER} Debian package"
${SUDO} dpkg --build ${PKG_NAME}_${PKG_VER} ${PKG_NAME}_${PKG_VER}-${PKG_REL}.${ARCH}.deb
cd ${PKG_NAME}_${PKG_VER}
echo "Creating compressed tar archive of ${PKG_NAME} ${PKG_VER} distribution"
tar cf - usr | gzip -9 > ../${PKG_NAME}_${PKG_VER}-${PKG_REL}.tgz

have_zip=`type -p zip`
[ "${have_zip}" ] || {
  ${SUDO} apt-get update
  ${SUDO} apt-get install zip -y
}
echo "Creating zip archive of ${PKG_NAME} ${PKG_VER} distribution"
zip -q -r ../${PKG_NAME}_${PKG_VER}-${PKG_REL}.zip usr

cd ..
[ "${GCI}" ] || {
    [ -d ../releases ] || mkdir ../releases
    [ -d ../releases/${PKG_VER} ] || mkdir ../releases/${PKG_VER}
    ${SUDO} cp *.deb *.tgz *.zip ../releases/${PKG_VER}
}