OPTION(WITH_EXASOL_GW_STORAGE_ENGINE
  "Build the Exasol Gateway proxy storage engine plugin (ha_exasol_gw.so)" OFF)

IF(NOT WITH_EXASOL_GW_STORAGE_ENGINE)
  SET(PLUGIN_exasol_gw NO CACHE STRING "How to build plugin exasol_gw" FORCE)
  MESSAGE(STATUS "Skipping Exasol Gateway storage engine (enable with -DWITH_EXASOL_GW_STORAGE_ENGINE=ON)")
  RETURN()
ENDIF()

MESSAGE(STATUS "Building Exasol Gateway proxy storage engine")

FIND_PACKAGE(ExasolGatewaySdk CONFIG QUIET)
IF(NOT TARGET ExasolGateway::C)
  FIND_PACKAGE(SessionGatewaySdk CONFIG QUIET)
ENDIF()
IF(NOT TARGET ExasolGateway::C)
  FIND_PATH(EXASOL_GATEWAY_SDK_INCLUDE_DIR sessiongw/c_api.h)
  FIND_LIBRARY(EXASOL_GATEWAY_SDK_LIBRARY NAMES SessionGatewaySdk)
  IF(NOT EXASOL_GATEWAY_SDK_INCLUDE_DIR OR NOT EXASOL_GATEWAY_SDK_LIBRARY)
    MESSAGE(FATAL_ERROR
      "ExasolGatewaySdk is required. Set ExasolGatewaySdk_DIR, "
      "CMAKE_PREFIX_PATH, or EXASOL_GATEWAY_SDK_INCLUDE_DIR and "
      "EXASOL_GATEWAY_SDK_LIBRARY.")
  ENDIF()
  ADD_LIBRARY(ExasolGateway::C SHARED IMPORTED)
  SET_TARGET_PROPERTIES(ExasolGateway::C PROPERTIES
    IMPORTED_LOCATION "${EXASOL_GATEWAY_SDK_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${EXASOL_GATEWAY_SDK_INCLUDE_DIR}")
ENDIF()

SET(EXASOL_GW_SOURCES
  exasol_arrow_ipc.cc
  exasol_native_write_batch.cc
  exasol_gw_pushdown.cc
  exasol_gw_sql_generator.cc
  exasol_gw_session.cc
  exasol_sessiongw_client.cc
  ha_exasol_gw.cc)

MYSQL_ADD_PLUGIN(exasol_gw ${EXASOL_GW_SOURCES} STORAGE_ENGINE MODULE_ONLY
  LINK_LIBRARIES ExasolGateway::C)
