-- Internal states
CREATE TYPE waiting_orders_state AS
(
    waiting_orders INTEGER,
    is_initialized BOOLEAN
);

-- Update function
CREATE OR REPLACE FUNCTION f_update(state waiting_orders_state, ok bigint,
                                                    pk int,
                                                    sk int,
                                                    ln int)
    RETURNS waiting_orders_state
    IMMUTABLE AS
$$
DECLARE
    result waiting_orders_state;
BEGIN
    result.waiting_orders = state.waiting_orders + 1;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Finalize function
CREATE OR REPLACE FUNCTION f_finalize(state waiting_orders_state)
    RETURNS INTEGER
    IMMUTABLE AS
$$
BEGIN
    RETURN state.waiting_orders;
END;
$$ LANGUAGE plpgsql;

-- Aggregate
CREATE OR REPLACE AGGREGATE WaitingOrdersAggregate (ok bigint,
    pk int,
    sk int,
    ln int,
    ...)
    (
    sfunc = f_update,
    stype = waiting_orders_state,
    finalfunc = f_finalize,
    stype.waiting_orders = 0,
    stype.is_initialized = false
    );

-- UDF, Wrapper
CREATE OR REPLACE FUNCTION WaitingOrdersWithCustomAgg(suppkey bigint)
    RETURNS bigint
    STABLE AS
$$
DECLARE
    skey bigint := suppkey;
    val  bigint := 0;
BEGIN
    SELECT WaitingOrdersAggregate(Q.ok, Q.pk, Q.sk, Q.ln, ...)
    INTO val
    FROM (SELECT L_ORDERKEY as ok, L_PARTKEY as pk, L_SUPPKEY as sk, L_LINENUMBER as ln
          FROM lineitem l1,
               orders
          WHERE l1.L_SUPPKEY = skey
            AND O_ORDERKEY = l1.L_ORDERKEY
            AND O_ORDERSTATUS = 'F'
            AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
            AND EXISTS(SELECT *
                       FROM lineitem L2
                       WHERE L2.L_ORDERKEY = l1.L_ORDERKEY
                         AND L2.L_SUPPKEY <> l1.L_SUPPKEY)
            AND NOT EXISTS(SELECT *
                           FROM lineitem L3
                           WHERE L3.L_ORDERKEY = l1.L_ORDERKEY
                             AND L3.L_SUPPKEY <> l1.L_SUPPKEY
                             AND L3.L_RECEIPTDATE > L3.L_COMMITDATE)) Q;
    RETURN val;
END;
$$ LANGUAGE plpgsql;

-- UDF calling
EXPLAIN ANALYZE
SELECT S_NAME, S_SUPPKEY
FROM supplier
WHERE WaitingOrdersWithCustomAgg(S_SUPPKEY) > 0;

