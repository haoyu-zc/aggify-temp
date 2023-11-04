CREATE OR REPLACE FUNCTION VolumeCustomer(orderkey bigint)
    RETURNS int
    STABLE
AS
$$
DECLARE
    ok  bigint         := orderkey;
    qty decimal(12, 2);
    i   int            := 0;
    d   decimal(12, 2) := 0;
BEGIN
    FOR qty IN (SELECT L_QUANTITY FROM lineitem WHERE L_ORDERKEY = ok)
        LOOP
            d := d + qty;
        END LOOP;

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
WHERE VolumeCustomer(O_ORDERKEY) = 1;
