CREATE OR REPLACE FUNCTION OrdersByCustomer(ckey integer)
    RETURNS integer
    STABLE AS
$$
DECLARE
    custkey integer := ckey;
    okey    bigint;
    val     integer := 0;
BEGIN
    FOR okey IN (SELECT O_ORDERKEY FROM orders WHERE O_CUSTKEY = custkey)
        LOOP
            val := val + 1;
        END LOOP;
    RETURN val;
END;
$$ LANGUAGE plpgsql;

/* UDF call */
EXPLAIN ANALYZE
SELECT C_CUSTKEY, OrdersByCustomer(C_CUSTKEY)
FROM customer;
