DROP TRIGGER patient_num_constraint ON patient_stratum;
DROP FUNCTION check_num_patient();

DROP TRIGGER patient_fct_constraint ON patient_stratum;
DROP FUNCTION check_fct_patient();

DROP TRIGGER patient_stratum_study_constraint ON patient_stratum;
DROP FUNCTION check_patient_stratum_study();

DROP TRIGGER stratum_num_constraint ON numeric_constraint;
DROP FUNCTION check_num_stratum();

DROP TRIGGER stratum_fct_constraint ON factor_constraint;
DROP FUNCTION check_fct_stratum();