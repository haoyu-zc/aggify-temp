-- Internal states
CREATE TYPE order_count_state AS
(
    order_count INTEGER,
    is_initialized BOOLEAN
);

-- Update function
CREATE OR REPLACE FUNCTION f_update(order_key BIGINT, val INTEGER)
    RETURNS order_count_state
    IMMUTABLE AS
$$
DECLARE
    result order_count_state;
BEGIN
    IF NOT state.is_initialized THEN
        state.is_initialized := true;
        state.order_count := val;
    END IF;
    result.order_count = state.order_count + 1;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Finalize function
CREATE OR REPLACE FUNCTION f_finalize()
    RETURNS INTEGER
    IMMUTABLE AS
$$
BEGIN
    RETURN state.order_count;
END;
$$ LANGUAGE plpgsql;

-- Aggregate
-- CREATE OR REPLACE AGGREGATE OrdersByCustomerAggregate (...) -- this ... refers the ... passed to OrdersByCustomerAggregate
CREATE OR REPLACE AGGREGATE OrdersByCustomerAggregate (order_key BIGINT, val INTEGER)
    (
    stype = order_count_state,
    sfunc = f_update,
    finalfunc = f_finalize,
    -- stype.order_count = 0,
    stype.is_initialized = false
    );

-- UDF, Wrapper
CREATE OR REPLACE FUNCTION OrdersByCustomerWithCustomAgg(cust_key INTEGER)
    RETURNS INTEGER
    STABLE AS
$$
DECLARE
    custkey integer := ckey;
    okey    bigint;
    val INTEGER;
BEGIN
    SELECT OrdersByCustomerAggregate(O_ORDERKEY, val)
    FROM orders
    WHERE O_CUSTKEY = cust_key
    INTO val;
    return val;
END;
$$ LANGUAGE plpgsql;

/* UDF call */
EXPLAIN ANALYZE
SELECT C_CUSTKEY, OrdersByCustomerWithCustomAgg(C_CUSTKEY)
FROM customer;
