-- Internal states
CREATE TYPE order_count_state AS
(
    order_count INTEGER,
    is_initialized BOOLEAN
);

-- Size function
CREATE OR REPLACE FUNCTION f_finalize(state order_count_state)
    RETURNS INTEGER
    IMMUTABLE AS
$$
BEGIN
    RETURN SELECT 2;
END;
$$ LANGUAGE plpgsql;

-- Update function
CREATE OR REPLACE FUNCTION f_update(state order_count_state, order_key BIGINT)
    RETURNS order_count_state
    IMMUTABLE AS
$$
DECLARE
    result order_count_state;
BEGIN
    result.order_count = state.order_count + 1;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Finalize function
CREATE OR REPLACE FUNCTION f_finalize(state order_count_state)
    RETURNS INTEGER
    IMMUTABLE AS
$$
BEGIN
    RETURN state.order_count;
END;
$$ LANGUAGE plpgsql;

-- Aggregate
CREATE OR REPLACE AGGREGATE OrdersByCustomerAggregate (BIGINT)
    (
    stype = order_count_state,
    sfunc = f_update,
    finalfunc = f_finalize,
    initcond = '(0, false)',
    );

-- UDF, Wrapper
CREATE OR REPLACE FUNCTION OrdersByCustomerWithCustomAgg(cust_key INTEGER)
    RETURNS INTEGER
    STABLE AS
$$
DECLARE
    val INTEGER;
BEGIN
    SELECT OrdersByCustomerAggregate(O_ORDERKEY)
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
