CREATE OR REPLACE FUNCTION WaitingOrders(suppkey bigint)
    RETURNS bigint STABLE AS
$$
DECLARE
    skey bigint := suppkey;
    val  bigint := 0;
    ok   bigint;
    pk   int;
    sk   int;
    ln   int;
BEGIN
    FOR ok, pk, sk, ln IN (SELECT L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER
                           FROM lineitem l1,
                                orders
                           WHERE l1.L_SUPPKEY = skey
                             AND O_ORDERKEY = l1.L_ORDERKEY
                             AND O_ORDERSTATUS = 'F'
                             AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
                             AND EXISTS(SELECT *
                                        FROM lineitem L2
                                        WHERE L2.L_ORDERKEY = l1.L_ORDERKEY
                                          AND L2.L_SUPPKEY <> l1.L_SUPPKEY)
                             AND NOT EXISTS(SELECT *
                                            FROM lineitem L3
                                            WHERE L3.L_ORDERKEY = l1.L_ORDERKEY
                                              AND L3.L_SUPPKEY <> l1.L_SUPPKEY
                                              AND L3.L_RECEIPTDATE > L3.L_COMMITDATE))
        LOOP
            val := val + 1;
        END LOOP;
    RETURN val;
END;
$$ LANGUAGE plpgsql;

-- UDF calling
EXPLAIN ANALYZE
SELECT S_NAME, S_SUPPKEY
FROM supplier
WHERE WaitingOrders(S_SUPPKEY) > 0;
