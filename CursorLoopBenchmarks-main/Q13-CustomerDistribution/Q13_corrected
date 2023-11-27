-- Type your code here, or load an example.
CREATE OR REPLACE FUNCTION OrdersByCustomerWithCustomAgg(cust_key INTEGER)
    RETURNS INTEGER
    STABLE AS
$$
DECLARE
    custkey integer := cust_key;
    okey    bigint;
    val INTEGER := 0;
BEGIN
    if exists (SELECT O_ORDERKEY FROM orders WHERE O_CUSTKEY = custkey) then
        val := (SELECT (O_ORDERKEY, val)
        FROM (SELECT O_ORDERKEY FROM orders WHERE O_CUSTKEY = custkey) S);
    end if;
    return val;
END;
$$ LANGUAGE plpgsql;

-- Q:

SELECT C_CUSTKEY, OrdersByCustomerWithCustomAgg(C_CUSTKEY)
FROM customer;
