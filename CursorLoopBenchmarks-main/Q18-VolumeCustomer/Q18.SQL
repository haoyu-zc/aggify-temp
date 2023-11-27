-- Internal states
CREATE TYPE volume_customer_accum AS
(
    volume DECIMAL(25, 5),
    is_initialized BOOLEAN
);

-- Update function
CREATE OR REPLACE FUNCTION f_update(
    volume DECIMAL(12, 2)
) RETURNS volume_customer_accum
    IMMUTABLE AS
$$
BEGIN
    IF NOT state.is_initialized THEN
        state.is_initialized := true;
        state.volume := volume;
    END IF;
    state.volume := state.volume + volume;
    RETURN state;
END;
$$ LANGUAGE plpgsql;

-- Finalize function
CREATE OR REPLACE FUNCTION f_finalize(state volume_customer_accum) RETURNS DECIMAL(25, 5)
    IMMUTABLE AS
$$
BEGIN
    RETURN state.volume;
END;
$$ LANGUAGE plpgsql;

-- Aggregate
CREATE OR REPLACE AGGREGATE volume_customer_agg(
    value DECIMAL(12, 2)
    ) (
    sfunc = f_update,
    stype = volume_customer_accum,
    finalfunc = f_finalize,
    stype.is_initialized = false
    );

-- UDF, Wrapper
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
