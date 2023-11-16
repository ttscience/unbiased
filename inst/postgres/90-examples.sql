INSERT INTO study (identifier, name, method_id, parameters)
VALUES ('TEST', 'Badanie testowe', 1, '{}');

INSERT INTO arm (study_id, name, ratio)
VALUES (1, 'placebo', 2),
       (1, 'active', 1);

INSERT INTO stratum (study_id, name, value_type)
VALUES (1, 'gender', 'factor');

INSERT INTO factor_constraint (stratum_id, value)
VALUES (1, 'F'), (1, 'M');

INSERT INTO patient (study_id, arm_id)
VALUES (1, 1);

INSERT INTO patient_stratum (patient_id, stratum_id, fct_value)
VALUES (1, 1, 'F');

UPDATE patient
SET used = true
WHERE id = 1;

-- Trigger properly raises an error here
/*
INSERT INTO numeric_constraint (stratum_id)
VALUES (1);
*/
