-- Type your code here, or load an example.
CREATE OR REPLACE FUNCTION VolumeCustomerWithCustomAgg(orderkey bigint)
    RETURNS int
    STABLE AS
$$
DECLARE
    ok bigint         := orderkey;
    i  int            := 0;
    d  decimal(12, 2) := 0;
BEGIN
    if exists (select L_QUANTITY from lineitem 
                WHERE L_ORDERKEY = ok) then
        d := (SELECT volume_customer_agg(L_QUANTITY, d) FROM 
                (select L_QUANTITY from lineitem 
                    WHERE L_ORDERKEY = ok) tmp);
    end if;
    IF d > 300 THEN
        i := 1;
    END IF;

    RETURN i;
END;
$$ LANGUAGE plpgsql;

-- Q:
SELECT O_ORDERKEY, O_TOTALPRICE
FROM orders
WHERE VolumeCustomerWithCustomAgg(O_ORDERKEY) = 1;
