CREATE OR REPLACE FUNCTION OrdersByCustomerWithNativeAgg(custkey integer)
    RETURNS integer
    STABLE
    AS
$$
DECLARE
    val integer := 0;
BEGIN
    SELECT COUNT(*)
    INTO val
    FROM orders
    WHERE O_CUSTKEY = custkey;
    RETURN val;
END
$$ LANGUAGE plpgsql;

/* UDF call */
EXPLAIN ANALYZE
SELECT C_CUSTKEY, OrdersByCustomerWithNativeAgg(C_CUSTKEY)
FROM customer;

/* Inlined UDF */
EXPLAIN ANALYZE SELECT c.c_custkey, e.total
FROM customer c
         LEFT OUTER JOIN (SELECT o_custkey, COUNT(*) as total
                          FROM orders
                          GROUP BY O_CUSTKEY) e ON c.c_custkey = e.O_CUSTKEY;