CREATE OR REPLACE PACKAGE MEX_TSIN IS
-- $Revision: 1.6 $
    -----------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2;

    PROCEDURE PARSE_CA_REGISTRY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_PSE_REGISTRY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_ENTITY_REGISTRY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_SC_REGISTRY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_TP_REGISTRY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_PRODUCT_REGISTRY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_PRODUCT_TYPE
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_REGISTRY_VERSION
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_POR_POD_ROLE
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_POR_POD_POINT
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_SOURCE_SINK_ROLE
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_SOURCE_SINK_POINT
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_MRD_RESOURCES
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );

    PROCEDURE PARSE_MRD_FLOWGATES
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR
    );
    --------------------------------------------------------
    PROCEDURE FETCH_TSIN_DATA
    (
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2,
        p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER
    );
    ----------------------------------------------------------
END MEX_TSIN;
/