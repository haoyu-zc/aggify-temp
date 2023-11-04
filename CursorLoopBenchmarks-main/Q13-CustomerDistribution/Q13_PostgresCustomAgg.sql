CREATE TYPE order_count_state AS
(
    order_count INTEGER
);

CREATE OR REPLACE FUNCTION order_count_statefunc(state order_count_state, order_key BIGINT)
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

CREATE OR REPLACE FUNCTION order_count_finalfunc(state order_count_state)
    RETURNS INTEGER
    IMMUTABLE AS
$$
BEGIN
    RETURN state.order_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION order_count_mergefunc(state1 order_count_state, state2 order_count_state)
    RETURNS order_count_state
    IMMUTABLE AS
$$
DECLARE
    merged_state order_count_state;
BEGIN
    merged_state.order_count := state1.order_count + state2.order_count;
    return merged_state;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE AGGREGATE OrdersByCustomerAggregate (BIGINT)
    (
    sfunc = order_count_statefunc,
    stype = order_count_state,
    finalfunc = order_count_finalfunc,
    initcond = '(0)',
    combinefunc = order_count_mergefunc,
    parallel = safe
    );

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

/* Inlined UDF */
EXPLAIN ANALYZE VERBOSE SELECT c.c_custkey, e.total
FROM customer c
         LEFT OUTER JOIN (SELECT o_custkey, OrdersByCustomerAggregate(o_custkey) as total
                          FROM orders
                          GROUP BY O_CUSTKEY) e ON c.c_custkey = e.O_CUSTKEY;
