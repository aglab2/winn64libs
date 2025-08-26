#! /bin/bash
# N64 MIPS GCC toolchain build/install script for Unix distributions
# originally based off libdragon's toolchain script,
# which was licensed under the Unlicense.
# (c) 2012-2021 DragonMinded and libDragon Contributors.

# modified by easyaspi314 to allow fscked toolchain setups

# Exit on error
set -e
set -x

INSTALL_PATH="/d/crash/sdk"

if ! mkdir -p "$INSTALL_PATH" || ! [ -w "$INSTALL_PATH" ]
then
    echo "Error accessing ${INSTALL_PATH}, perhaps try again with sudo?"
    exit 1
fi

echo "Would you like to enable C++? This takes longer to compile. (y/N)"

IFS='$\n' read ENABLE_CXX

case ${ENABLE_CXX:-n} in
    n*|N*)
        ENABLE_LANGUAGES="c"
        ;;
    y*|Y*)
        ENABLE_LANGUAGES="c,c++"
        ;;
esac

echo "== Base ABI =="

echo "Note that most programs will break if not compiled with the same flags,"
echo "and assembly programs will most likely need to be rewritten."
echo
echo "Which ABI would you like to use?"
echo "32/n32/64/eabi (default 32)"

IFS='$\n' read ABI

ABI=${ABI:-32}

case $ABI in
   32|eabi)
       GPRSIZE=32
       MIPS="mips"
       ;;
   64|n32)
      GPRSIZE=64
      MIPS="mips64"
      ;;
   *)
      exit 1;
      ;;
esac

echo "What type of floating point ABI would you like to use?"

echo "Options:"
echo " 0: soft float (slow)"
echo " 1: f32 in even regs, f64 in register pairs (default)"
echo " 2: f32 in even and odd regs, f64 is emulated"
[ $GPRSIZE -eq 64 ] && echo " 3: f32 in any regs, f64 in any regs"

IFS='$\n' read FPMODE

case ${FPMODE:-1} in
    0)
        FP_FLAGS="--with-float=soft"
        ;;
    1)
        FP_FLAGS="--with-float=hard --with-fp-32=32 --with-fpu=double"
        ;;
    2)
        FP_FLAGS="--with-float=hard --with-fp-32=32 --with-odd-spreg-32=yes --with-fpu=single" 
        ;;
    3)
        FP_FLAGS="--with-float=hard --with-fp-32=64 --with-odd-spreg-32=yes --with-fpu=single"
        ;;
    *)
        exit 1
        ;;

esac

echo "== ABI fsckery =="
echo
echo "The next two options are very non-standard modifications but if used wisely"
echo "can improve performance"
echo
echo "Are there any registers you would like to override as call-saved?"
echo "Note that this can and will break things, and if you choose the wrong registers"
echo "even recompiled code will explode."
echo
echo "Example: 14 t4 f16"

IFS='$\n' read SAVED_REGS

if [ -n "$SAVED_REGS" ]; then
    for i in $SAVED_REGS; do
        REG_OVERRIDES="${REG_OVERRIDES} -fcall-saved-$i"
    done 
fi

echo "Are there any registers you would like to override as fixed? (e.g. for global variables in registers if you are evil)"

IFS='$\n' read FIXED_REGS

if [ -n "$FIXED_REGS" ]; then
    for i in $FIXED_REGS; do
        REG_OVERRIDES="${REG_OVERRIDES} -ffixed-$i"
    done 
fi

if [ -z "$ABI_FLAGS" ]
then
    case $ABI in
        32)
            ABI_FLAGS="-mno-abicalls -fno-PIC -mgp32 ${REG_OVERRIDES}"
            ;;
        n32)
            ABI_FLAGS="-mno-abicalls -fno-PIC ${REG_OVERRIDES}"
            ;;
        n64)
            ABI_FLAGS="-mno-abicalls -fno-PIC ${REG_OVERRIDES}"
            ;;
        eabi)
            ABI_FLAGS="-mno-abicalls -mgp32 -fno-PIC ${REG_OVERRIDES}"
            ;;
    esac
fi



TARGET_FLAGS="${TARGET_FLAGS:--march=vr4300 -mtune=vr4300 -mfix4300}"
OPT_FLAGS="${OPT_FLAGS:--mno-check-zero-division -Os}"

# Set PATH for newlib to compile using GCC for MIPS N64 (pass 1)
export PATH="$PATH:$INSTALL_PATH/bin"

# Determine how many parallel Make jobs to run based on CPU count
JOBS="${JOBS:-`getconf _NPROCESSORS_ONLN`}"
JOBS="${JOBS:-1}" # If getconf returned nothing, default to 1

# Dependency source libs (Versions)
BINUTILS_V=2.30
GCC_V=14.3.0
NEWLIB_V=4.1.0

# Check if a command-line tool is available: status 0 means "yes"; status 1 means "no"
command_exists () {
  (command -v "$1" >/dev/null 2>&1)
  return $?
}

# Download the file URL using wget or curl (depending on which is installed)
download () {
  if   command_exists aria2c ; then aria2c -c -s 16 -x 16 "$1"
  elif command_exists wget ; then wget -c  "$1"
  elif command_exists curl ; then curl -LO "$1"
  else
    echo "Install `wget` or `curl` or `aria2c` to download toolchain sources" 1>&2
    return 1
  fi
}

# Dependency source: Download stage
test -f "binutils-$BINUTILS_V.tar.xz" || download "https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_V.tar.xz"
test -f "gcc-$GCC_V.tar.xz"           || download "https://ftp.gnu.org/gnu/gcc/gcc-$GCC_V/gcc-$GCC_V.tar.xz"
test -f "newlib-$NEWLIB_V.tar.gz"     || download "https://sourceware.org/pub/newlib/newlib-$NEWLIB_V.tar.gz"

# Dependency source: Extract stage
test -d "binutils-$BINUTILS_V" || { \
                                      tar -xJf "binutils-$BINUTILS_V.tar.xz"; \
                                      pushd "binutils-$BINUTILS_V"; \
                                      patch -p1 < "../gas-vr4300.patch"; \
                                      patch -p1 < "../no-fp-warn.patch"; \
                                      patch -p1 < "../sdata_merging_bfd.patch"; \
                                      popd; \
                                  }
test -d "gcc-$GCC_V"           || { \
                                      tar -xJf "gcc-$GCC_V.tar.xz"; \
                                      pushd "gcc-$GCC_V"; \
                                      patch -p1 < "../bb-reorder.patch"; \
                                      patch -p1 < "../gcc-vr4300.patch"; \
                                      patch -p1 < "../mips_floats.patch"; \
                                      patch -p1 < "../mingw.patch"; \
                                      sed -i 's/set_std_c23 (false/set_std_c17 (false/' gcc/c-family/c-opts.cc \
                                      contrib/download_prerequisites; \
                                      popd; \
                                  }
test -d "newlib-$NEWLIB_V"     || tar -xzf "newlib-$NEWLIB_V.tar.gz"

# Compile binutils
cd "binutils-$BINUTILS_V"
CFLAGS="-O2" CXXFLAGS="-O2" ./configure \
	--disable-debug \
    --enable-checking=release \
    --prefix="$INSTALL_PATH" \
    --target=${MIPS}-elf \
    --with-cpu=mips64vr4300 \
    --program-prefix=mips-n64- \
    --disable-werror \
    --enable-plugins \
    --enable-lto
make -j "$JOBS"
make install

export RANLIB_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-ranlib
export CC_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-gcc
export CXX_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-g++
export AR_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-ar
export STRIP_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-strip
export CFLAGS_FOR_TARGET="${ABI_FLAGS} ${TARGET_FLAGS} -ffreestanding ${OPT_FLAGS} -O2"
export CXXFLAGS_FOR_TARGET="${ABI_FLAGS} ${TARGET_FLAGS} -ffreestanding ${OPT_FLAGS} -O2"

# Compile GCC for MIPS N64 outside of the source tree
cd ..
rm -rf gcc_compile
mkdir -p gcc_compile
cd gcc_compile
CFLAGS="-O2" CXXFLAGS="-O2" \
../"gcc-$GCC_V"/configure \
    --prefix="$INSTALL_PATH" \
    --with-gnu-as=${INSTALL_PATH}/bin/mips-n64-as \
    --with-gnu-ld=${INSTALL_PATH}/bin/mips-n64-ld \
    --target=${MIPS}-elf \
    --program-prefix=mips-n64- \
    --with-arch=vr4300 \
    --with-tune=vr4300 \
    --enable-languages=$ENABLE_LANGUAGES \
    --with-newlib \
    --disable-libssp \
    --disable-multilib \
    --disable-shared \
    --with-gcc \
    --disable-threads \
    --disable-win32-registry \
    --disable-nls \
    --disable-werror \
    --with-abi=${ABI} \
    $FP_FLAGS \
    --with-system-zlib \
    --with-specs="${ABI_FLAGS} ${TARGET_FLAGS}" \
    --enable-plugins \
    --enable-plugin \
    --enable-lto
make clean -j "$JOBS"
make all-gcc -j "$JOBS"
make install-gcc

# Compile newlib

cd ../"newlib-$NEWLIB_V"
./configure \
    --target=${MIPS}-elf \
    --prefix="$INSTALL_PATH" \
    --with-cpu=mips64vr4300 \
    --disable-threads \
    --disable-shared \
    --disable-libssp \
    --disable-werror
make -j "$JOBS"
make install

# Finish compiling libgcc now that newlib is available

cd ../gcc_compile
make all -j "$JOBS"
make install-strip
cd .. 

echo "The toolchain has been successfully installed to ${INSTALL_PATH}"
