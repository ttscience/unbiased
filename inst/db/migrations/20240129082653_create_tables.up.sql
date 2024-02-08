CREATE TABLE study (
  id          SERIAL PRIMARY KEY,
  identifier  VARCHAR(12) NOT NULL,
  name        VARCHAR(255) NOT NULL,
  method      VARCHAR(255) NOT NULL,
  parameters  JSONB,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT now(),
  sys_period  TSTZRANGE NOT NULL
);

COMMENT ON TABLE study IS 'Stores information about various studies conducted.';
COMMENT ON COLUMN study.id IS 'An auto-incrementing primary key uniquely identifying each study.';
COMMENT ON COLUMN study.identifier IS 'A unique, short textual identifier for the study (max 12 characters).';
COMMENT ON COLUMN study.name IS 'Provides the full name or title of the study.';
COMMENT ON COLUMN study.method IS 'A randomization method name.';
COMMENT ON COLUMN study.parameters IS 'JSONB column to store parameters related to the study.';
COMMENT ON COLUMN study.timestamp IS 'Timestamp of when the record was created, defaults to current time.';
COMMENT ON COLUMN study.sys_period IS 'TSTZRANGE type used for temporal versioning to track the validity period of each record.';

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

COMMENT ON TABLE arm IS 'Represents the treatment arms within each study.';
COMMENT ON COLUMN arm.id IS 'An auto-incrementing primary key that uniquely identifies each arm.';
COMMENT ON COLUMN arm.study_id IS 'A foreign key that links each arm to its corresponding study.';
COMMENT ON COLUMN arm.name IS 'Provides a descriptive name for the treatment arm.';
COMMENT ON COLUMN arm.ratio IS 'Specifies the proportion of patients allocated to this arm. It defaults to 1 and must always be positive.';
COMMENT ON COLUMN arm.sys_period IS 'TSTZRANGE type used for temporal versioning to track the validity period of each record.';

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

COMMENT ON TABLE stratum IS 'Defines the strata for patient categorization within each study.';

COMMENT ON COLUMN stratum.id IS 'An auto-incrementing primary key that uniquely identifies each stratum.';
COMMENT ON COLUMN stratum.study_id IS 'A foreign key that links the stratum to a specific study.';
COMMENT ON COLUMN stratum.name IS 'Provides a descriptive name for the stratum, such as a particular demographic or clinical characteristic.';
COMMENT ON COLUMN stratum.value_type IS 'Indicates the type of value the stratum represents, limited to two types: ''factor'' or ''numeric''. ''factor'' represents categorical data, while ''numeric'' represents numerical data. This distinction is crucial as it informs the data validation logic applied in the system.';
COMMENT ON COLUMN stratum.sys_period IS 'TSTZRANGE type used for temporal versioning to track the validity period of each record.';

CREATE TABLE stratum_level (
    stratum_id  INT NOT NULL,
    level       VARCHAR(255) NOT NULL,
    CONSTRAINT fk_stratum_level
        FOREIGN KEY (stratum_id)
        REFERENCES stratum (id) ON DELETE CASCADE,
    CONSTRAINT uc_stratum_level
        UNIQUE (stratum_id, level)
);
COMMENT ON TABLE stratum_level IS 'Keeps allowed stratum factor levels.';

COMMENT ON COLUMN stratum_level.stratum_id IS 'A foreign key that links the stratum level to a specific stratum.';
COMMENT ON COLUMN stratum_level.level IS 'Level label, has to be unique within stratum.';

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

COMMENT ON TABLE factor_constraint IS 'Defines constraints for strata of the ''factor'' type in studies. This table stores allowable values for each factor stratum, ensuring data consistency and integrity.';

COMMENT ON COLUMN factor_constraint.stratum_id IS 'A foreign key that links the constraint to a specific stratum in the ''stratum'' table.';
COMMENT ON COLUMN factor_constraint.value IS 'Represents the specific allowable value for the factor stratum. This could be a categorical label like ''male'' or ''female'' for a gender stratum, for example.';
COMMENT ON COLUMN factor_constraint.sys_period IS 'TSTZRANGE type used for temporal versioning to track the validity period of each record.';

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

COMMENT ON TABLE numeric_constraint IS 'Specifies constraints for strata of the ''numeric'' type in studies. This table defines the permissible range (minimum and maximum values) for each numeric stratum.';

COMMENT ON COLUMN numeric_constraint.stratum_id IS 'A foreign key that links the constraint to a specific numeric stratum in the ''stratum'' table.';
COMMENT ON COLUMN numeric_constraint.min_value IS 'Defines the minimum allowable value for the stratum''s numeric values. Can be NULL, indicating that there is no lower bound.';
COMMENT ON COLUMN numeric_constraint.max_value IS 'Defines the maximum allowable value for the stratum''s numeric values. Can be NULL, indicating that there is no upper bound.';
COMMENT ON COLUMN numeric_constraint.sys_period IS 'TSTZRANGE type used for temporal versioning to track the validity period of each record.';

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


COMMENT ON TABLE patient IS 'Represents individual patients participating in the studies.';
COMMENT ON COLUMN patient.id IS 'An auto-incrementing primary key that uniquely identifies each patient.';
COMMENT ON COLUMN patient.study_id IS 'A foreign key linking the patient to a specific study.';
COMMENT ON COLUMN patient.arm_id IS 'An optional foreign key that links the patient to a specific treatment arm within the study.';
COMMENT ON COLUMN patient.used IS 'A boolean flag indicating the state of the patient in the randomization process.';
COMMENT ON COLUMN patient.sys_period IS 'Type TSTZRANGE, used for temporal versioning to track the validity period of each record.';
COMMENT ON CONSTRAINT patient_arm_study ON patient IS 'Ensures referential integrity between patients, studies, and arms. It also cascades deletions to maintain consistency when a study or arm is deleted.';
COMMENT ON CONSTRAINT used_with_arm ON patient IS 'Ensures logical consistency by allowing ''used'' to be true only if the patient is assigned to an arm (i.e., ''arm_id'' is not NULL). This prevents scenarios where a patient is marked as used but not assigned to any treatment arm.';


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


COMMENT ON TABLE patient_stratum IS 'Associates patients with specific strata and records the corresponding stratum values.';
COMMENT ON COLUMN patient_stratum.patient_id IS 'A foreign key that links to the ''patient'' table, identifying the patient.';
COMMENT ON COLUMN patient_stratum.stratum_id IS 'A foreign key that links to the ''stratum'' table, identifying the stratum to which the patient belongs.';
COMMENT ON COLUMN patient_stratum.fct_value IS 'Stores the categorical (factor) value for the patient in the corresponding stratum, if applicable.';
COMMENT ON COLUMN patient_stratum.num_value IS 'Stores the numerical value for the patient in the corresponding stratum, if applicable.';
COMMENT ON COLUMN patient_stratum.sys_period IS 'Type TSTZRANGE, used for temporal versioning to track the validity period of each record.';
COMMENT ON CONSTRAINT fk_patient ON patient_stratum IS 'Links each patient-stratum pairing to the respective tables.';
COMMENT ON CONSTRAINT fk_stratum_2 ON patient_stratum IS 'Links each patient-stratum pairing to the respective tables.';
COMMENT ON CONSTRAINT chk_value_exists ON patient_stratum IS 'Ensures that either a factor or numeric value is provided for each record, aligning with the nature of the stratum.';
COMMENT ON CONSTRAINT chk_one_value_only ON patient_stratum IS 'Ensures that each record has either a factor or a numeric value, but not both, maintaining the integrity of the data by ensuring it matches the stratum type (factor or numeric).';
COMMENT ON CONSTRAINT uc_patient_stratum ON patient_stratum IS 'Ensures that each patient-stratum pairing is unique.';
