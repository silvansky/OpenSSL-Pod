Pod::Spec.new do |s|
  s.name            = "OpenSSL"
  s.version         = "1.0.210"
  s.summary         = "OpenSSL is an SSL/TLS and Crypto toolkit. Deprecated in Mac OS and gone in iOS, this spec gives your project non-deprecated OpenSSL support."
  s.author          = "OpenSSL Project <openssl-dev@openssl.org>"

  s.homepage        = "https://github.com/silvansky/OpenSSL-Pod"
  s.source          = { :http => "https://openssl.org/source/openssl-1.0.2j.tar.gz", :sha1 => "bdfbdb416942f666865fa48fe13c2d0e588df54f"}
  s.source_files    = "opensslIncludes/openssl/*.h"
  s.header_dir      = "openssl"
  s.license         = { :type => 'OpenSSL (OpenSSL/SSLeay)', :file => 'LICENSE' }

  s.prepare_command = <<-CMD
    VERSION="1_0_2j"
    SDKVERSION=`xcrun --sdk iphoneos --show-sdk-version 2> /dev/null`
    MIN_SDK_VERSION_FLAG="-miphoneos-version-min=7.0"

    BASEPATH="${PWD}"
    CURRENTPATH="${HOME}/tmp/openssl"
    ARCHS="i386 x86_64 armv7 armv7s arm64"
    DEVELOPER=`xcode-select -print-path`

    echo "BASEPATH: ${BASEPATH}"
    echo "CURRENTPATH: ${CURRENTPATH}"
    rm -rf "${CURRENTPATH}"
    mkdir -p "${CURRENTPATH}"
    mkdir -p "${CURRENTPATH}/bin"
    ls
    cp -a . "${CURRENTPATH}/openssl-${VERSION}"
    cd "${CURRENTPATH}"
    cd "openssl-${VERSION}"

    curl -OL "https://github.com/openssl/openssl/archive/OpenSSL_${VERSION}.tar.gz"
    tar -xzvf OpenSSL_${VERSION}.tar.gz
    cd "openssl-OpenSSL_${VERSION}"

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
        # Fix build conflicts with BoringSSL
        sed -ie "s/md5_block_data_order/openssl_shadowed_md5_block_data_order/g" "crypto/md32_common.h"
        sed -ie "s/md5_block_data_order/openssl_shadowed_md5_block_data_order/g" "crypto/md5/md5_dgst.c"
        sed -ie "s/md5_block_data_order/openssl_shadowed_md5_block_data_order/g" "crypto/md5/md5_locl.h"

        PLATFORM="iPhoneOS"
      fi

      export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
      export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"

      echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
      echo "Please stand by..."

      export CC="${DEVELOPER}/usr/bin/gcc -arch ${ARCH} ${MIN_SDK_VERSION_FLAG}"
      mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
      LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-openssl-${VERSION}.log"

      LIPO_LIBSSL="${LIPO_LIBSSL} ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/libssl.a"
      LIPO_LIBCRYPTO="${LIPO_LIBCRYPTO} ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/libcrypto.a"

      ./Configure ${CONFIGURE_FOR} --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
      sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} !" "Makefile"

      make >> "${LOG}" 2>&1
      make all install_sw >> "${LOG}" 2>&1
      make clean >> "${LOG}" 2>&1

    done


    echo "Build library..."
    rm -rf "${BASEPATH}/lib/"
    mkdir -p "${BASEPATH}/lib/"
    lipo -create ${LIPO_LIBSSL}    -output "${BASEPATH}/lib/libssl.a"
    lipo -create ${LIPO_LIBCRYPTO} -output "${BASEPATH}/lib/libcrypto.a"

    echo "Copying headers..."
    rm -rf "${BASEPATH}/opensslIncludes/"
    mkdir -p "${BASEPATH}/opensslIncludes/"
    cp -RL "${CURRENTPATH}/openssl-${VERSION}/openssl-OpenSSL_${VERSION}/include/openssl" "${BASEPATH}/opensslIncludes/"

    echo "Copying license file..."
    cp "${CURRENTPATH}/openssl-${VERSION}/openssl-OpenSSL_${VERSION}/LICENSE" "${BASEPATH}/LICENSE"

    cd "${BASEPATH}"

    echo "Building done."

    echo "Cleaning up..."
    rm -rf "${CURRENTPATH}"
    echo "Done."
  CMD

  s.ios.deployment_target   = "8.0"
  s.ios.public_header_files = "opensslIncludes/openssl/*.h"
  s.ios.vendored_libraries  = "lib/libcrypto.a", "lib/libssl.a"

  s.libraries             = 'crypto', 'ssl'
  s.requires_arc          = false

end
