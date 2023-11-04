/* Postgres version of UDF */
CREATE OR REPLACE FUNCTION MinCostSupp(pk bigint)
    RETURNS char(25)
    STABLE AS
$$
DECLARE
    key         bigint         := pk;
    fetchedCost decimal(15, 2);
    fetchedName char(25);
    minCost     decimal(25, 2) := 100000;
    val         char(25);
BEGIN
    FOR fetchedCost, fetchedName IN (SELECT PS_SUPPLYCOST, S_NAME
                                     FROM partsupp,
                                          supplier
                                     WHERE PS_PARTKEY = key
                                       AND PS_SUPPKEY = S_SUPPKEY)
        LOOP
            IF fetchedCost < minCost THEN
                minCost := fetchedCost;
                val := fetchedName;
            END IF;
        END LOOP;
    RETURN val;
END;
$$ LANGUAGE plpgsql;

/* UDF call */
EXPLAIN ANALYZE
SELECT P_PARTKEY, MinCostSupp(P_PARTKEY)
FROM part;
