-- Type your code here, or load an example.
CREATE OR REPLACE FUNCTION WaitingOrdersWithCustomAgg(suppkey bigint)
    RETURNS bigint
    STABLE AS
$$
DECLARE
    skey bigint := suppkey;
    val  bigint := 0;
BEGIN
    if exists ((SELECT L_ORDERKEY as ok, L_PARTKEY as pk, L_SUPPKEY as sk, L_LINENUMBER as ln
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
                                    AND L3.L_RECEIPTDATE > L3.L_COMMITDATE))) then
        val := (SELECT ordersbycustomeraggregate(Q.ok, val)
                FROM (SELECT L_ORDERKEY as ok, L_PARTKEY as pk, L_SUPPKEY as sk, L_LINENUMBER as ln
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
                                        AND L3.L_RECEIPTDATE > L3.L_COMMITDATE)) Q);
    end if;
    RETURN val;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION WaitingOrdersWithCustomAgg(suppkey bigint)
    RETURNS bigint
    STABLE AS
$$
DECLARE
    skey bigint := suppkey;
    val  bigint := 0;
BEGIN
    val := (SELECT case when count(*) > 0 then
            ordersbycustomeraggregate(Q.ok, val) else val end
            FROM (SELECT L_ORDERKEY as ok, L_PARTKEY as pk, L_SUPPKEY as sk, L_LINENUMBER as ln
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
                                    AND L3.L_RECEIPTDATE > L3.L_COMMITDATE)) Q);
    RETURN val;
END;
$$ LANGUAGE plpgsql;

-- Q:
SELECT S_NAME, S_SUPPKEY
FROM supplier
WHERE WaitingOrdersWithCustomAgg(S_SUPPKEY) > 0;
