CREATE TYPE volume_customer_accum AS
(
    volume DECIMAL(25, 5)
);

CREATE OR REPLACE FUNCTION volume_customer_sfunc(
    state volume_customer_accum,
    volume DECIMAL(12, 2)
) RETURNS volume_customer_accum
    IMMUTABLE AS
$$
BEGIN
    state.volume := state.volume + volume;
    RETURN state;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION volume_customer_finalfunc(state volume_customer_accum) RETURNS DECIMAL(25, 5)
    IMMUTABLE AS
$$
BEGIN
    RETURN state.volume;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION volume_customer_mergefunc(state1 volume_customer_accum, state2 volume_customer_accum)
    RETURNS volume_customer_accum
    IMMUTABLE AS
$$
DECLARE
    merged_volume volume_customer_accum;
BEGIN
    merged_volume.volume := state1.volume + state2.volume;
    return merged_volume;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE AGGREGATE volume_customer_agg(
    value DECIMAL(12, 2)
    ) (
    sfunc = volume_customer_sfunc,
    stype = volume_customer_accum,
    finalfunc = volume_customer_finalfunc,
    initcond = '(0.0)',
    combinefunc = volume_customer_mergefunc,
    parallel = safe
    );


CREATE OR REPLACE FUNCTION VolumeCustomerWithCustomAgg(orderkey bigint)
    RETURNS int
    STABLE AS
$$
DECLARE
    ok bigint         := orderkey;
    i  int            := 0;
    d  decimal(12, 2) := 0;
BEGIN
    SELECT volume_customer_agg(L_QUANTITY) INTO d FROM lineitem WHERE L_ORDERKEY = ok;

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
WHERE VolumeCustomerWithCustomAgg(O_ORDERKEY) = 1;

EXPLAIN ANALYZE
SELECT O_ORDERKEY, O_TOTALPRICE
FROM orders
         LEFT OUTER JOIN (SELECT l_orderkey, volume_customer_agg(l_quantity) as vol FROM lineitem GROUP BY l_orderkey) e
                         ON o_orderkey = e.l_orderkey
WHERE vol > 300;
