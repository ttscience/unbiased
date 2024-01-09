CREATE TABLE study_history (LIKE study);

CREATE TRIGGER study_versioning
BEFORE INSERT OR UPDATE OR DELETE ON study
FOR EACH ROW
EXECUTE PROCEDURE versioning('sys_period', 'study_history', true);

CREATE TABLE arm_history (LIKE arm);

CREATE TRIGGER arm_versioning
BEFORE INSERT OR UPDATE OR DELETE ON arm
FOR EACH ROW
EXECUTE PROCEDURE versioning('sys_period', 'arm_history', true);

CREATE TABLE stratum_history (LIKE stratum);

CREATE TRIGGER stratum_versioning
BEFORE INSERT OR UPDATE OR DELETE ON stratum
FOR EACH ROW
EXECUTE PROCEDURE versioning('sys_period', 'stratum_history', true);

CREATE TABLE factor_constraint_history (LIKE factor_constraint);

CREATE TRIGGER fct_constraint_versioning
BEFORE INSERT OR UPDATE OR DELETE ON factor_constraint
FOR EACH ROW
EXECUTE PROCEDURE versioning('sys_period', 'factor_constraint_history', true);

CREATE TABLE numeric_constraint_history (LIKE numeric_constraint);

CREATE TRIGGER num_constraint_versioning
BEFORE INSERT OR UPDATE OR DELETE ON numeric_constraint
FOR EACH ROW
EXECUTE PROCEDURE versioning('sys_period', 'numeric_constraint_history', true);

CREATE TABLE patient_history (LIKE patient);

CREATE TRIGGER patient_versioning
BEFORE INSERT OR UPDATE OR DELETE ON patient
FOR EACH ROW
EXECUTE PROCEDURE versioning('sys_period', 'patient_history', true);

CREATE TABLE patient_stratum_history (LIKE patient_stratum);

CREATE TRIGGER patient_stratum_versioning
BEFORE INSERT OR UPDATE OR DELETE ON patient_stratum
FOR EACH ROW
EXECUTE PROCEDURE versioning('sys_period', 'patient_stratum_history', true);
