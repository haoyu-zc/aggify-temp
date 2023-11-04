CREATE OR REPLACE FUNCTION VolumeCustomerWithNativeAgg(orderkey bigint)
    RETURNS int
    STABLE AS
$$
DECLARE
    ok bigint         := orderkey;
    i  int            := 0;
    d  decimal(12, 2) := 0;
BEGIN
    SELECT SUM(L_QUANTITY) INTO d FROM lineitem WHERE L_ORDERKEY = ok;

    IF d > 300 THEN
        i := 1;
    END IF;

    RETURN i;
END;
$$ LANGUAGE plpgsql;


--UDF call
EXPLAIN ANALYZE
SELECT O_ORDERKEY, O_TOTALPRICE
FROM orders
WHERE VolumeCustomerWithNativeAgg(O_ORDERKEY) = 1;

EXPLAIN ANALYZE
SELECT O_ORDERKEY, O_TOTALPRICE
FROM orders
         LEFT OUTER JOIN (SELECT l_orderkey, SUM(l_quantity) as vol FROM lineitem GROUP BY l_orderkey) e
                         ON o_orderkey = e.l_orderkey
WHERE vol > 300;
