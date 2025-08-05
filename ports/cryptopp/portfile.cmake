vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
string(REPLACE "." "_" CRYPTOPP_VERSION "${VERSION}")


if("pem-pack" IN_LIST FEATURES)

    vcpkg_from_github(
            OUT_SOURCE_PATH CMAKE_SOURCE_PATH
            REPO abdes/cryptopp-cmake
            REF "CRYPTOPP_${CRYPTOPP_VERSION}"
            SHA512 3ec33b107ab627a514e1ebbc4b6522ee8552525f36730d9b5feb85e61ba7fc24fd36eb6050e328c6789ff60d47796beaa8eebf7dead787a34395294fae9bb733
            HEAD_REF master
            PATCHES
            fix_pem.patch
    )

    vcpkg_from_github(
            OUT_SOURCE_PATH SOURCE_PATH
            REPO weidai11/cryptopp
            REF "CRYPTOPP_${CRYPTOPP_VERSION}"
            SHA512 28a67141155c9c15e3e6a2173b3a8487cc38a2a2ade73bf4a09814ca541be6b06e9a501be26f7e2f42a2f80df21b076aa5d8ad4224dc0a1f8d7f3b24deae465e
            HEAD_REF master
            PATCHES
            patch.patch
            cryptopp.patch
    )

    vcpkg_from_github(
            OUT_SOURCE_PATH PEM_PACK_SOURCE_PATH
            REPO noloader/cryptopp-pem
            REF 64782e531d116ffbf83ca80614ac408dbb3fd775
            SHA512 154cf045f822a0da54a88ceb89d5b42cb8ad2eface73eb32a8eee0c4e60be10f4692442f1913f58e894b46412884907f5f70d99d1691ccf52e0aa50c9c9943cd
            HEAD_REF master
    )
#
        file(GLOB PEM_PACK_FILES
            ${PEM_PACK_SOURCE_PATH}/*.h
            ${PEM_PACK_SOURCE_PATH}/*.cpp
        )
#        file(INSTALL ${PEM_PACK_FILES} DESTINATION "${CURRENT_PACKAGES_DIR}/include/${PORT}")
        foreach(PEM_PACK_FILE ${PEM_PACK_FILES})
            file(COPY ${PEM_PACK_FILE} DESTINATION "${SOURCE_PATH}")
        endforeach()

else()
    vcpkg_from_github(
            OUT_SOURCE_PATH CMAKE_SOURCE_PATH
            REPO abdes/cryptopp-cmake
            REF "CRYPTOPP_${CRYPTOPP_VERSION}"
            SHA512 3ec33b107ab627a514e1ebbc4b6522ee8552525f36730d9b5feb85e61ba7fc24fd36eb6050e328c6789ff60d47796beaa8eebf7dead787a34395294fae9bb733
            HEAD_REF master
    )

    vcpkg_from_github(
            OUT_SOURCE_PATH SOURCE_PATH
            REPO weidai11/cryptopp
            REF "CRYPTOPP_${CRYPTOPP_VERSION}"
            SHA512 28a67141155c9c15e3e6a2173b3a8487cc38a2a2ade73bf4a09814ca541be6b06e9a501be26f7e2f42a2f80df21b076aa5d8ad4224dc0a1f8d7f3b24deae465e
            HEAD_REF master
            PATCHES
            patch.patch
            cryptopp.patch
    )
endif()


file(COPY "${CMAKE_SOURCE_PATH}/cryptopp" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_SOURCE_PATH}/cmake" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_SOURCE_PATH}/test" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_SOURCE_PATH}/cryptopp/cryptoppConfig.cmake" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_SOURCE_PATH}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")



# disable assembly on ARM Windows to fix broken build
if (VCPKG_TARGET_IS_WINDOWS AND VCPKG_TARGET_ARCHITECTURE MATCHES "^arm")
    set(CRYPTOPP_DISABLE_ASM "ON")
elseif(NOT DEFINED CRYPTOPP_DISABLE_ASM) # Allow disabling using a triplet file
    set(CRYPTOPP_DISABLE_ASM "OFF")
endif()

# Dynamic linking should be avoided for Crypto++ to reduce the attack surface,
# so generate a static lib for both dynamic and static vcpkg targets.
# See also:
#   https://www.cryptopp.com/wiki/Visual_Studio#Dynamic_Runtime_Linking
#   https://www.cryptopp.com/wiki/Visual_Studio#The_DLL

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DCRYPTOPP_SOURCES=${SOURCE_PATH}
        -DCRYPTOPP_BUILD_SHARED=OFF
        -DBUILD_STATIC=ON
        -DCRYPTOPP_BUILD_TESTING=OFF
        -DCRYPTOPP_BUILD_DOCUMENTATION=OFF
        -DDISABLE_ASM=${CRYPTOPP_DISABLE_ASM}
        -DUSE_INTERMEDIATE_OBJECTS_TARGET=OFF # Not required when we build static only
        -DCMAKE_POLICY_DEFAULT_CMP0063=NEW # Honor "<LANG>_VISIBILITY_PRESET" properties
    MAYBE_UNUSED_VARIABLES
        BUILD_STATIC
        USE_INTERMEDIATE_OBJECTS_TARGET
        CMAKE_POLICY_DEFAULT_CMP0063
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH share/cmake/cryptopp)

if(NOT VCPKG_BUILD_TYPE)
    file(RENAME "${CURRENT_PACKAGES_DIR}/debug/share/pkgconfig" "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
endif()
file(RENAME "${CURRENT_PACKAGES_DIR}/share/pkgconfig" "${CURRENT_PACKAGES_DIR}/lib/pkgconfig")
vcpkg_fixup_pkgconfig()

# There is no way to suppress installation of the headers and resource files in debug build.
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")


if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

# Handle copyright
file(COPY "${SOURCE_PATH}/License.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(RENAME "${CURRENT_PACKAGES_DIR}/share/${PORT}/License.txt" "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright")
