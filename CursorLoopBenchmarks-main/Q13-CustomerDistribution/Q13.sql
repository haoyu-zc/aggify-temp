CREATE OR REPLACE FUNCTION OrdersByCustomer(ckey integer)
    RETURNS integer
    STABLE AS
$$
DECLARE
    val     integer := 0;
BEGIN
    SELECT INTO val count_rows(O_ORDERKEY)
    FROM (
        SELECT O_ORDERKEY FROM orders WHERE O_CUSTKEY = custkey
    ) AS q;
END;
$$ LANGUAGE plpgsql;

-- State Transition Function
CREATE OR REPLACE FUNCTION count_state_transition(current_count bigint, next_value anyelement)
    RETURNS bigint AS
$$
BEGIN
    -- Increment the current count by 1
    RETURN current_count + 1;
END;
$$ LANGUAGE plpgsql;

-- Custom Aggregate Function
CREATE AGGREGATE count_rows(anyelement) (
    SFUNC = count_state_transition,  -- State transition function
    STYPE = bigint,                  -- State data type
    INITCOND = '0'                   -- Initial condition of the state
);

/* UDF call */
EXPLAIN ANALYZE
SELECT C_CUSTKEY, OrdersByCustomer(C_CUSTKEY)
FROM customer;