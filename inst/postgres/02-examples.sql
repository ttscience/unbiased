INSERT INTO method (name)
VALUES ('simple');

INSERT INTO stratum (name, value_type)
VALUES ('gender', 'factor');

INSERT INTO factor_constraint (stratum_id, value)
VALUES (1, 'X');

-- Trigger properly raises an error here
/*
INSERT INTO numeric_constraint (stratum_id)
VALUES (1);
*/
