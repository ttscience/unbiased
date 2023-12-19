CREATE EXTENSION temporal_tables;

-- Table: method
-- Purpose: Holds the available randomization methods used in clinical studies.
-- Each method is uniquely identified by an auto-incrementing ID.
-- The 'name' column stores the name of the randomization method.
-- The 'sys_period' column, of type TSTZRANGE, is used for temporal versioning,
-- tracking the period during which each record is considered valid and current.
CREATE TABLE method (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  sys_period  TSTZRANGE NOT NULL
);

-- Table: study
-- Purpose: Stores information about various studies conducted.
-- 'id' is an auto-incrementing primary key uniquely identifying each study.
-- 'identifier' is a unique, short textual identifier for the study (max 12 characters).
-- 'name' provides the full name or title of the study.
-- 'method_id' is a foreign key linking to the 'method' table, indicating the randomization method used in the study.
-- 'sys_period' is of type TSTZRANGE, used for temporal versioning to track the validity period of each record.
-- The 'study_method' constraint ensures referential integrity, linking each study to a valid randomization method.
CREATE TABLE study (
  id          SERIAL PRIMARY KEY,
  identifier  VARCHAR(12) NOT NULL,
  name        VARCHAR(255) NOT NULL,
  method_id   INT NOT NULL,
  parameters  JSONB,
  -- timestamp   TIMESTAMPTZ NOT NULL DEFAULT now(),
  sys_period  TSTZRANGE NOT NULL,
  CONSTRAINT study_method
    FOREIGN KEY (method_id)
    REFERENCES method (id)
);

-- Table: arm
-- Purpose: Represents the treatment arms within each study.
-- 'id' is an auto-incrementing primary key that uniquely identifies each arm.
-- 'study_id' is a foreign key that links each arm to its corresponding study.
-- 'name' provides a descriptive name for the treatment arm.
-- 'ratio' specifies the proportion of patients allocated to this arm. It defaults to 1 and must always be positive.
-- 'sys_period' is of type TSTZRANGE, used for temporal versioning to track the validity period of each record.
-- The 'arm_study' foreign key constraint ensures that each arm is associated with a valid study.
-- The 'uc_arm_study' unique constraint ensures that each combination of 'id' and 'study_id' is unique,
--    which is important for maintaining data integrity across studies.
-- The 'ratio_positive' check constraint ensures that the ratio is always greater than 0,
--    maintaining logical consistency in the patient allocation process.
CREATE TABLE arm (
  id          SERIAL PRIMARY KEY,
  study_id    INT NOT NULL,
  name        VARCHAR(255) NOT NULL,
  ratio       INT NOT NULL DEFAULT 1,
  sys_period  TSTZRANGE NOT NULL,
  CONSTRAINT arm_study
    FOREIGN KEY (study_id)
    REFERENCES study (id) ON DELETE CASCADE,
  CONSTRAINT uc_arm_study
    UNIQUE (id, study_id),
  CONSTRAINT ratio_positive
    CHECK (ratio > 0)
);

-- Table: stratum
-- Purpose: Defines the strata for patient categorization within each study.
-- 'id' is an auto-incrementing primary key that uniquely identifies each stratum.
-- 'study_id' is a foreign key that links the stratum to a specific study.
-- 'name' provides a descriptive name for the stratum, such as a particular demographic or clinical characteristic.
-- 'value_type' indicates the type of value the stratum represents, limited to two types: 'factor' or 'numeric'.
--       'factor' represents categorical data, while 'numeric' represents numerical data.
--       This distinction is crucial as it informs the data validation logic applied in the system.
-- 'sys_period' is of type TSTZRANGE, used for temporal versioning to track the validity period of each record.
-- The 'fk_study' foreign key constraint ensures that each stratum is associated with a valid study and cascades deletions.
-- The 'chk_value_type' check constraint ensures that the 'value_type' field only contains allowed values ('factor' or 'numeric'),
--    enforcing data integrity and consistency in the type of stratum values.
-- Subsequent validation checks in the system (like 'check_fct_stratum') use the 'value_type' field to ensure data integrity,
--    by verifying that constraints on data (factor or numeric) align with the stratum type.
CREATE TABLE stratum (
  id          SERIAL PRIMARY KEY,
  study_id    INT NOT NULL,
  name        VARCHAR(255) NOT NULL,
  value_type  VARCHAR(12),
  sys_period  TSTZRANGE NOT NULL,
  CONSTRAINT fk_study
    FOREIGN KEY (study_id)
    REFERENCES study (id) ON DELETE CASCADE,
  CONSTRAINT chk_value_type
    CHECK (value_type IN ('factor', 'numeric'))
);

-- Table: stratum_level
-- Purpose: Keeps allowed stratum factor levels
-- 'id' is an auto-incrementing primary key that uniquely identifies each stratum.
-- 'level' level label, has to be unique within stratum
CREATE TABLE stratum_level (
    stratum_id  INT NOT NULL,
    level       VARCHAR(255) NOT NULL,
    CONSTRAINT fk_stratum_level
        FOREIGN KEY (stratum_id)
        REFERENCES stratum (id) ON DELETE CASCADE,
    CONSTRAINT uc_stratum_level
        UNIQUE (stratum_id, level)
);

-- Table: factor_constraint
-- Purpose: Defines constraints for strata of the 'factor' type in studies.
-- This table stores allowable values for each factor stratum, ensuring data consistency and integrity.
-- 'stratum_id' is a foreign key that links the constraint to a specific stratum in the 'stratum' table.
-- 'value' represents the specific allowable value for the factor stratum.
--       This could be a categorical label like 'male' or 'female' for a gender stratum, for example.
-- 'sys_period' is of type TSTZRANGE, used for temporal versioning to track the validity period of each record.
-- The 'factor_stratum' foreign key constraint ensures that each constraint is associated with a valid factor type stratum.
-- The 'uc_stratum_value' unique constraint ensures that each combination of 'stratum_id' and 'value' is unique within the table.
--       This prevents duplicate entries for the same stratum and value, maintaining the integrity of the constraint data.
CREATE TABLE factor_constraint (
  stratum_id  INT NOT NULL,
  value       VARCHAR(255) NOT NULL,
  sys_period  TSTZRANGE NOT NULL,
  CONSTRAINT factor_stratum
    FOREIGN KEY (stratum_id)
    REFERENCES stratum (id) ON DELETE CASCADE,
  CONSTRAINT uc_stratum_value
    UNIQUE (stratum_id, value)
);

-- Table: numeric_constraint
-- Purpose: Specifies constraints for strata of the 'numeric' type in studies.
-- This table defines the permissible range (minimum and maximum values) for each numeric stratum.
-- 'stratum_id' is a foreign key that links the constraint to a specific numeric stratum in the 'stratum' table.
-- 'min_value' and 'max_value' define the allowable range for the stratum's numeric values.
--       For example, if the stratum represents age, 'min_value' and 'max_value' might define the age range for a study group.
--       Either of these columns can be NULL, indicating that there is no lower or upper bound, respectively.
-- 'sys_period' is of type TSTZRANGE, used for temporal versioning to track the validity period of each record.
-- The 'numeric_stratum' foreign key constraint ensures that each constraint is associated with a valid numeric type stratum.
-- The 'uc_stratum' unique constraint ensures that there is only one constraint entry per 'stratum_id'.
-- The 'chk_min_max' check constraint ensures that 'min_value' is always less than or equal to 'max_value',
--       maintaining logical consistency. If either value is NULL, the check constraint still holds valid as per SQL standards.
CREATE TABLE numeric_constraint (
  stratum_id  INT NOT NULL,
  min_value   FLOAT,
  max_value   FLOAT,
  sys_period  TSTZRANGE NOT NULL,
  CONSTRAINT numeric_stratum
    FOREIGN KEY (stratum_id)
    REFERENCES stratum (id) ON DELETE CASCADE,
  CONSTRAINT uc_stratum
    UNIQUE (stratum_id),
  CONSTRAINT chk_min_max
    -- NULL is ok in checks, no need to test for it
    CHECK (min_value <= max_value)
);

-- Table: patient
-- Purpose: Represents individual patients participating in the studies.
-- 'id' is an auto-incrementing primary key that uniquely identifies each patient.
-- 'study_id' is a foreign key linking the patient to a specific study.
-- 'arm_id' is an optional foreign key that links the patient to a specific treatment arm within the study.
--       For instance, in methods like simple randomization, 'arm_id' is assigned as patients are randomized.
--       Conversely, in methods such as block randomization, 'arm_id' might be pre-assigned based on a predetermined randomization list.
--       This flexible approach allows for accommodating various randomization methods and their unique requirements.
-- 'used' is a boolean flag indicating the state of the patient in the randomization process.
--       In methods like simple randomization, patients are entered into this table only when they are randomized,
--       meaning 'used' will always be true for these entries, as there are no pre-plans in this method.
--       For other methods, such as block randomization, 'used' is utilized to mark patients as 'used'
--       according to a pre-planned randomization list, accommodating pre-assignment in these scenarios.
--       This design allows the system to adapt to different randomization strategies effectively.
-- 'sys_period' is of type TSTZRANGE, used for temporal versioning to track the validity period of each record.
-- The 'patient_arm_study' foreign key constraint ensures referential integrity between patients, studies, and arms.
--       It also cascades deletions to maintain consistency when a study or arm is deleted.
-- The 'used_with_arm' check constraint ensures logical consistency by allowing 'used' to be true only if the patient
--       is assigned to an arm (i.e., 'arm_id' is not NULL).
--       This prevents scenarios where a patient is marked as used but not assigned to any treatment arm.
CREATE TABLE patient (
  id          SERIAL PRIMARY KEY,
  study_id    INT NOT NULL,
  arm_id      INT,
  used        BOOLEAN NOT NULL DEFAULT false,
  -- timestamp   TIMESTAMPTZ NOT NULL DEFAULT now(),
  sys_period  TSTZRANGE NOT NULL,
  CONSTRAINT patient_arm_study
    FOREIGN KEY (arm_id, study_id)
    REFERENCES arm (id, study_id) ON DELETE CASCADE,
  CONSTRAINT used_with_arm
    CHECK (NOT used OR arm_id IS NOT NULL)
);

-- Table: patient_stratum
-- Purpose: Associates patients with specific strata and records the corresponding stratum values.
-- 'patient_id' is a foreign key that links to the 'patient' table, identifying the patient.
-- 'stratum_id' is a foreign key that links to the 'stratum' table, identifying the stratum to which the patient belongs.
-- 'fct_value' stores the categorical (factor) value for the patient in the corresponding stratum, if applicable.
-- 'num_value' stores the numerical value for the patient in the corresponding stratum, if applicable.
--       For example, if a stratum represents a demographic category, 'fct_value' might be used;
--       if it represents a measurable characteristic like age, 'num_value' might be used.
-- 'sys_period' is of type TSTZRANGE, used for temporal versioning to track the validity period of each record.
-- The 'fk_patient' and 'fk_stratum_2' foreign key constraints link each patient-stratum pairing to the respective tables.
-- The 'chk_value_exists' check constraint ensures that either a factor or numeric value is provided for each record,
--       aligning with the nature of the stratum.
-- The 'chk_one_value_only' check constraint ensures that each record has either a factor or a numeric value, but not both,
--       maintaining the integrity of the data by ensuring it matches the stratum type (factor or numeric).
CREATE TABLE patient_stratum (
  patient_id  INT NOT NULL,
  stratum_id  INT NOT NULL,
  fct_value   VARCHAR(255),
  num_value   FLOAT,
  sys_period  TSTZRANGE NOT NULL,
  CONSTRAINT fk_patient
    FOREIGN KEY (patient_id)
    REFERENCES patient (id) ON DELETE CASCADE,
  CONSTRAINT fk_stratum_2
    FOREIGN KEY (stratum_id)
    REFERENCES stratum (id) ON DELETE CASCADE,
  CONSTRAINT chk_value_exists
    -- Either factor or numeric value must be given
    CHECK (fct_value IS NOT NULL OR num_value IS NOT NULL),
  CONSTRAINT chk_one_value_only
    -- Can't give both factor and numeric value
    CHECK (fct_value IS NULL OR num_value IS NULL),
  CONSTRAINT uc_patient_stratum
    UNIQUE (patient_id, stratum_id)
);

-- Stratum constraint checks

CREATE OR REPLACE FUNCTION check_fct_stratum()
RETURNS trigger AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM stratum
    -- Checks that column value is correct
    WHERE id = NEW.stratum_id AND value_type = 'factor'
  ) THEN
    RAISE EXCEPTION 'Can''t set factor constraint for non-factor stratum.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER stratum_fct_constraint
BEFORE INSERT ON factor_constraint
FOR EACH ROW
EXECUTE PROCEDURE check_fct_stratum();


CREATE OR REPLACE FUNCTION check_num_stratum()
RETURNS trigger AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM stratum
    -- Checks that column value is correct
    WHERE id = NEW.stratum_id AND value_type = 'numeric'
  ) THEN
    RAISE EXCEPTION 'Can''t set numeric constraint for non-numeric stratum.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER stratum_num_constraint
BEFORE INSERT ON numeric_constraint
FOR EACH ROW
EXECUTE PROCEDURE check_num_stratum();

-- Patient stratum value checks

-- Ensure that patients and strata are assigned to the same study.
CREATE OR REPLACE FUNCTION check_patient_stratum_study()
RETURNS trigger AS $$
BEGIN
  DECLARE
    patient_study INT := (
      SELECT study_id FROM patient
      WHERE id = NEW.patient_id
    );
    stratum_study INT := (
      SELECT study_id FROM stratum
      WHERE id = NEW.stratum_id
    );
  BEGIN
    IF (patient_study <> stratum_study) THEN
      RAISE EXCEPTION 'Stratum and patient must be assigned to the same study.';
    END IF;
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER patient_stratum_study_constraint
BEFORE INSERT ON patient_stratum
FOR EACH ROW
EXECUTE PROCEDURE check_patient_stratum_study();

-- Validate and enforce factor stratum values.
CREATE OR REPLACE FUNCTION check_fct_patient()
RETURNS trigger AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM stratum
    WHERE id = NEW.stratum_id AND value_type = 'factor'
  ) THEN
    IF (NEW.fct_value IS NULL) THEN
      RAISE EXCEPTION 'Factor stratum requires a factor value.';
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM factor_constraint
      WHERE stratum_id = NEW.stratum_id AND value = NEW.fct_value
    ) THEN
      RAISE EXCEPTION 'Factor value not specified as allowed.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER patient_fct_constraint
BEFORE INSERT ON patient_stratum
FOR EACH ROW
EXECUTE PROCEDURE check_fct_patient();

-- Validate and enforce numeric stratum values within specified constraints.
CREATE OR REPLACE FUNCTION check_num_patient()
RETURNS trigger AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM stratum
    WHERE id = NEW.stratum_id AND value_type = 'numeric'
  ) THEN
    IF (NEW.num_value IS NULL) THEN
      RAISE EXCEPTION 'Numeric stratum requires a numeric value.';
    END IF;
    DECLARE
      min_value FLOAT := (
        SELECT min_value FROM numeric_constraint
        WHERE stratum_id = NEW.stratum_id
      );
      max_value FLOAT := (
        SELECT max_value FROM numeric_constraint
        WHERE stratum_id = NEW.stratum_id
      );
    BEGIN
      IF (min_value IS NOT NULL AND NEW.num_value < min_value) THEN
        RAISE EXCEPTION 'New value is lower than minimum allowed value.';
      END IF;
      IF (max_value IS NOT NULL AND NEW.num_value > max_value) THEN
        RAISE EXCEPTION 'New value is greater than maximum allowed value.';
      END IF;
    END;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER patient_num_constraint
BEFORE INSERT ON patient_stratum
FOR EACH ROW
EXECUTE PROCEDURE check_num_patient();
