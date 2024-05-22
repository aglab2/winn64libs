How to build HackerSM64 using MinGW on Windows. Compilers SDK will take ~1Gb of disk space + cmder takes ~400MB and python takes ~150MB totally in roughly ~1.5GB of disk space.

1) Download necessary tools
 * [Cmder](https://cmder.app/) - click "Download Full" to have git
 * [winlibs](https://github.com/brechtsanders/winlibs_mingw/releases/download/14.1.0posix-18.1.5-11.0.1-msvcrt-r1/winlibs-x86_64-posix-seh-gcc-14.1.0-mingw-w64msvcrt-11.0.1-r1.zip) - using MSVCRT runtime without LLVM
 * [winn64libs](https://github.com/aglab2/winn64libs/releases/download/1.0/winn64libs.zip)
 * [Python](https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe)

2) Install python using downloaded exe. Select "Use admin priviliges when installer py.exe" and "Add python.exe to PATH". Click "Customize installation". Unselect all checkboxes. Only select checkboxes "Documentation", "pip" and "for all users (requires admin priviliges)". Click "Next". Unselect all checkboxes. Only select "Install Python 3.12 for all users", "Add Python to environment variables" and "Precompile standard library". Click "Install", wait for it to finish. Click "Disable path length limit". Click "Close". Go to folder when python was installed (likely "C:/Program Files/Python312". Copy "python.exe" to "python3.exe".

3) Extract cmder.zip folder. For convenience, i will use folder "C:/cmder". Launch "cmder.exe".

4) Extract winlibs and winn64libs folders. I will use dir "C:/" for convenience. I suggest using short folders without any whitespaces. I assume that folders were unpacked in "C:/winlibs" and "C:/n64libs". Setup folders extraction to have "bin" in the root like "C:/winlibs/bin" and "C:/n64libs/bin"
5) In search bar search for "Edit the system environment variables". Click on "Environment Variables...". in "System Variables" double click on "Path" entry. Click "New", then "Browse" and select "C:/winlibs/bin". Perform the same for "C:/n64libs/bin". In "User variables from admin" click on "Path", select "%USERPROFILE%/AppData/Local/Microsoft/WindowsApps", click "Delete".
6) Launch Cmder and let it do its preparations.
7) Ensure that compilers work: execute "gcc -v" and "mips-n64-gcc -v". You should observe the output similar to the following:
```
λ gcc -v
Using built-in specs.
COLLECT_GCC=gcc
COLLECT_LTO_WRAPPER=D:/winlibs/bin/../libexec/gcc/x86_64-w64-mingw32/14.1.0/lto-wrapper.exe
OFFLOAD_TARGET_NAMES=nvptx-none
Target: x86_64-w64-mingw32
Configured with: ../configure --prefix=/R/winlibs64_stage/inst_gcc-14.1.0/share/gcc --build=x86_64-w64-mingw32 --host=x86_64-w64-mingw32 --enable-offload-targets=nvptx-none --with-pkgversion='MinGW-W64 x86_64-msvcrt-posix-seh, built by Brecht Sanders, r1' --with-tune=generic --enable-checking=release --enable-threads=posix --disable-sjlj-exceptions --disable-libunwind-exceptions --disable-serial-configure --disable-bootstrap --enable-host-shared --enable-plugin --disable-default-ssp --disable-rpath --disable-libstdcxx-debug --disable-version-specific-runtime-libs --with-stabs --disable-symvers --enable-languages=c,c++,fortran,lto,objc,obj-c++ --disable-gold --disable-nls --disable-stage1-checking --disable-win32-registry --disable-multilib --enable-ld --enable-libquadmath --enable-libada --enable-libssp --enable-libstdcxx --enable-lto --enable-fully-dynamic-string --enable-libgomp --enable-graphite --enable-mingw-wildcard --enable-libstdcxx-time --enable-libstdcxx-pch --with-mpc=/d/Prog/winlibs64_stage/custombuilt --with-mpfr=/d/Prog/winlibs64_stage/custombuilt --with-gmp=/d/Prog/winlibs64_stage/custombuilt --with-isl=/d/Prog/winlibs64_stage/custombuilt --disable-libstdcxx-backtrace --enable-install-libiberty --enable-__cxa_atexit --without-included-gettext --with-diagnostics-color=auto --enable-clocale=generic --with-libiconv --with-system-zlib --with-build-sysroot=/R/winlibs64_stage/gcc-14.1.0/build_mingw/mingw-w64 CFLAGS='-I/d/Prog/winlibs64_stage/custombuilt/include/libdl-win32   -march=nocona -msahf -mtune=generic -O2 -Wno-error=format' CXXFLAGS='-Wno-int-conversion  -march=nocona -msahf -mtune=generic -O2' LDFLAGS='-pthread -Wl,--no-insert-timestamp -Wl,--dynamicbase -Wl,--high-entropy-va -Wl,--nxcompat -Wl,--tsaware' LD=/d/Prog/winlibs64_stage/custombuilt/share/binutils/bin/ld.exe
Thread model: posix
Supported LTO compression algorithms: zlib zstd
gcc version 14.1.0 (MinGW-W64 x86_64-msvcrt-posix-seh, built by Brecht Sanders, r1)

λ mips-n64-gcc -v
Using built-in specs.
COLLECT_GCC=mips-n64-gcc
COLLECT_LTO_WRAPPER=d:/crash/sdk/bin/../libexec/gcc/mips-elf/12.2.0/lto-wrapper.exe
Target: mips-elf
Configured with: ../gcc-12.2.0/configure --prefix=/d/crash/sdk --with-gnu-as=/d/crash/sdk/bin/mips-n64-as --with-gnu-ld=/d/crash/sdk/bin/mips-n64-ld --target=mips-elf --program-prefix=mips-n64- --with-arch=vr4300 --with-tune=vr4300 --enable-languages=c,c++ --with-newlib --disable-libssp --disable-multilib --disable-shared --with-gcc --disable-threads --disable-win32-registry --disable-nls --disable-werror --with-abi=32 --with-float=hard --with-fp-32=32 --with-fpu=double --with-system-zlib --with-specs='-mno-abicalls -fno-PIC -mgp32  -march=vr4300 -mtune=vr4300 -mfix4300'
Thread model: single
Supported LTO compression algorithms: zlib zstd
gcc version 12.2.0 (GCC)
```
Ensure that "MinGW-W64 x86_64-msvcrt-posix-seh" is present in gcc output.

7) Clone repo using [tutorial](https://github.com/aglab2/tutorials/blob/main/git.md). Base repo is https://github.com/aglab2/HackerSM64-MinGW. I assume that repository was forked and cloned to C:\HackerSM64-MinGW 
8) Place legally obtained "baserom.us.z64" in C:\HackerSM64-MinGW.
9) To build the repository, change directory to "C:\HackerSM64-MinGW" in cmder and use command "mingw32-make -j12". Please change "12" to amount of CPU cores.
```
λ mingw32-make
Building tools...
Building ROM...
```
