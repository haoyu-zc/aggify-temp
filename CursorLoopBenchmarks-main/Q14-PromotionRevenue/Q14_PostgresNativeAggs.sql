CREATE OR REPLACE FUNCTION PromoRevenueWithNativeAgg(partkey integer)
    RETURNS decimal(25, 5)
    STABLE
AS
$$
DECLARE
    val decimal(25, 5);
BEGIN
    SELECT SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT))
    INTO val
    FROM lineitem
    WHERE L_PARTKEY = partkey;
    RETURN val;
END;
$$
    LANGUAGE plpgsql;

/* UDF call */
EXPLAIN ANALYZE
SELECT P_PARTKEY, PromoRevenueWithNativeAgg(P_PARTKEY)
from part
where P_TYPE like 'PROMO%%';

EXPLAIN ANALYZE
SELECT p.P_PARTKEY, e.revenue
FROM part p
         LEFT OUTER JOIN (SELECT l_partkey, SUM(l_extendedprice * (1 - l_discount)) as revenue
                            FROM lineitem
                            GROUP BY l_partkey) e ON e.L_PARTKEY = p.p_partkey
WHERE p.P_TYPE LIKE 'PROMO%%';