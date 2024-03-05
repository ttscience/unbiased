DROP TRIGGER patient_stratum_versioning ON patient_stratum;
DROP TABLE patient_stratum_history;

DROP TRIGGER patient_versioning ON patient;
DROP TABLE patient_history;

DROP TRIGGER num_constraint_versioning ON numeric_constraint;
DROP TABLE numeric_constraint_history;

DROP TRIGGER fct_constraint_versioning ON factor_constraint;
DROP TABLE factor_constraint_history;

DROP TRIGGER stratum_versioning ON stratum;
DROP TABLE stratum_history;

DROP TRIGGER arm_versioning ON arm;
DROP TABLE arm_history;

DROP TRIGGER study_versioning ON study;
DROP TABLE study_history;