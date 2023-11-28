-- Type your code here, or load an example.
CREATE OR REPLACE FUNCTION MinCostSuppWithCustomAgg(pk BIGINT)
RETURNS CHAR(25)
LANGUAGE plpgsql AS $$
DECLARE
    key         bigint         := pk;
    val         CHAR(25);
    pmin_cost   DECIMAL(25, 2) := 100000;
BEGIN
    if exists (SELECT PS_SUPPLYCOST, S_NAME
                                     FROM partsupp,
                                          supplier
                                     WHERE PS_PARTKEY = key
                                       AND PS_SUPPKEY = S_SUPPKEY) then
        val := (SELECT MinCostSuppAggregate(PS_SUPPLYCOST, S_NAME, pmin_cost)
                FROM (SELECT PS_SUPPLYCOST, S_NAME
                                        FROM partsupp,
                                            supplier
                                        WHERE PS_PARTKEY = key
                                        AND PS_SUPPKEY = S_SUPPKEY) tmp);
    end if;                                    
    RETURN val;
END;
$$;

-- Q:
SELECT P_PARTKEY, MinCostSuppWithCustomAgg(P_PARTKEY)
FROM part;
