Pod::Spec.new do |s|
  s.name            = "OpenSSL"
  s.version         = "1.0.108"
  s.summary         = "OpenSSL is an SSL/TLS and Crypto toolkit. Deprecated in Mac OS and gone in iOS, this spec gives your project non-deprecated OpenSSL support."
  s.author          = "OpenSSL Project <openssl-dev@openssl.org>"

  s.homepage        = "https://github.com/FredericJacobs/OpenSSL-Pod"
  s.license         = 'BSD-style Open Source'
  s.source          = { :http => "https://www.openssl.org/source/openssl-1.0.1h.tar.gz", :sha1 => "b2239599c8bf8f7fc48590a55205c26abe560bf8"}
  s.preserve_paths  = "file.tgz", "opensslIncludes/*"
  s.source_files    = "opensslIncludes/*.h", "**/*.h"
  s.header_dir      = "openssl"
  s.license	        = { :type => 'OpenSSL (OpenSSL/SSLeay)', :file => 'LICENSE.txt' }

  s.prepare_command = <<-CMD
    VERSION="1.0.1h"
    SDKVERSION=`/usr/bin/xcodebuild -version -sdk 2> /dev/null | grep SDKVersion | tail -n 1 |  awk '{ print $2 }'`

    CURRENTPATH=`pwd`
    ARCHS="i386 x86_64 armv7 armv7s arm64"
    DEVELOPER=`xcode-select -print-path`

    mkdir -p "${CURRENTPATH}/bin"
    mkdir -p "${CURRENTPATH}/lib"
    mkdir -p "${CURRENTPATH}/opensslIncludes"
    mkdir -p "${CURRENTPATH}/opensslIncludes/openssl"

    tar -xzf file.tgz

    cd openssl-${VERSION}
    cd include/openssl

    for link in $(find . -type l)
      do
        dir=$(readlink $link)
        cp $dir ../../../opensslIncludes/openssl
    done

    cd ../..
    for ARCH in ${ARCHS}
    do
      CONFIGURE_FOR="iphoneos-cross"

      if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ] ;
      then
        PLATFORM="iPhoneSimulator"
        if [ "${ARCH}" == "x86_64" ] ;
        then
          CONFIGURE_FOR="darwin64-x86_64-cc"
        fi
      else
        sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
        PLATFORM="iPhoneOS"
      fi

      export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
      export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"

      echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
      echo "Please stand by..."

      export CC="${DEVELOPER}/usr/bin/gcc -arch ${ARCH} -miphoneos-version-min=${SDKVERSION}"
      mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
      LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-openssl-${VERSION}.log"

      ./Configure ${CONFIGURE_FOR} --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
      sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} !" "Makefile"

      make >> "${LOG}" 2>&1
      make install >> "${LOG}" 2>&1
      make clean >> "${LOG}" 2>&1
    done


    echo "Build library..."
    lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/lib/libssl.a  ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/lib/libssl.a -output ${CURRENTPATH}/lib/libssl.a
    lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/lib/libcrypto.a -output ${CURRENTPATH}/lib/libcrypto.a

    echo "Building done."
    echo "Cleaning up..."
    rm -rf ${CURRENTPATH}/openssl-${VERSION}
    rm -R ${CURRENTPATH}/bin
    rm -rf file.tgz
    echo "Done."
  CMD

  s.ios.platform            = :ios
  s.ios.public_header_files = "opensslIncludes/*.h"
  s.ios.vendored_libraries  = "lib/libcrypto.a", "lib/libssl.a"

  s.libraries	            = 'crypto', 'ssl'
  s.requires_arc            = false

end
