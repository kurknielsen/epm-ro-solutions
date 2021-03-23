CREATE OR REPLACE PACKAGE MM_SEM_IC_OFFER IS

    -- Author  : JHUMPHRIES
    -- Created : 4/3/2007 12:52:18 PM
    -- Purpose : Build XML pieces of submission, query, and cancellation of Interconnector offers

    --Revision: $Revision: 1.7 $
    -- This function returns the version information, when queried. Used only for version management.
    -- %return Version information.
    FUNCTION WHAT_VERSION RETURN VARCHAR2;

    FUNCTION CREATE_SUBMISSION_XML
    (
        p_DATE           IN DATE,
        p_TRANSACTION_ID IN NUMBER,
        p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) RETURN XMLTYPE;

    FUNCTION CREATE_QUERY_XML
    (
        p_DATE           IN DATE,
        p_TRANSACTION_ID IN NUMBER,
        p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) RETURN XMLTYPE;

    FUNCTION PARSE_QUERY_XML
    (
        p_TRANSACTION_IDs IN NUMBER_COLLECTION,
        p_DATE           IN DATE,
        p_RESPONSE       IN XMLTYPE,
        p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) RETURN VARCHAR2;

    FUNCTION PARSE_SUBMISSION_RESPONSE_XML
    (
        p_TRANSACTION_IDs IN NUMBER_COLLECTION,
        p_DATE           IN DATE,
        p_RESPONSE       IN XMLTYPE,
        p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) RETURN VARCHAR2;

    FUNCTION GET_TRANSACTION_IDs
	(
		p_DATE IN DATE,
		p_ACCOUNT_NAME IN VARCHAR2,
		p_GATE_WINDOW IN VARCHAR2,
		p_RESPONSE IN XMLTYPE
	) RETURN NUMBER_COLLECTION;

END MM_SEM_IC_OFFER;
/
