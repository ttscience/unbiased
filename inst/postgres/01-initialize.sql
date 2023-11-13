CREATE TABLE method (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL
);

CREATE TABLE study (
  id          SERIAL PRIMARY KEY,
  method_id   INT NOT NULL,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT study_method
    FOREIGN KEY (method_id)
    REFERENCES id (method)
);

CREATE TABLE arm (
  id          SERIAL PRIMARY KEY,
  study_id    INT NOT NULL,
  name        TEXT NOT NULL,
  ratio       INT NOT NULL DEFAULT 1,
  CONSTRAINT arm_study
    FOREIGN KEY (study_id)
    REFERENCES study (id) ON DELETE CASCADE,
  CONSTRAINT uc_arm_study
    UNIQUE (id, study_id)
);

CREATE TABLE stratum (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  value_type  TEXT,
  CONSTRAINT chk_value_type
    CHECK (value_type IN ('factor', 'numeric', 'integer'))
);

CREATE TABLE stratum_in_study (
  stratum_id  INT NOT NULL,
  study_id    INT NOT NULL,
  CONSTRAINT fk_stratum
    FOREIGN KEY (stratum_id)
    REFERENCES stratum (id) ON DELETE CASCADE,
  CONSTRAINT fk_study
    FOREIGN KEY (study_id)
    REFERENCES study (id) ON DELETE CASCADE
);

-- TODO: Add trigger to check for stratum value type = 'factor'
CREATE TABLE factor_constraint (
  stratum_id  INT NOT NULL,
  value       TEXT NOT NULL,
  CONSTRAINT factor_stratum
    FOREIGN KEY (stratum_id)
    REFERENCES stratum (id) ON DELETE CASCADE,
  CONSTRAINT uc_stratum_value
    UNIQUE (stratum_id, value)
);

-- TODO: Add trigger to check for stratum value type = 'numeric' / 'integer'
CREATE TABLE numeric_constraint (
  stratum_id  INT NOT NULL,
  min_value   DOUBLE,
  max_value   DOUBLE,
  CONSTRAINT numeric_stratum
    FOREIGN KEY (stratum_id)
    REFERENCES stratum (id) ON DELETE CASCADE,
  CONSTRAINT uc_stratum
    UNIQUE (stratum_id)
);

CREATE TABLE patient (
  id          SERIAL PRIMARY KEY,
  study_id    INT NOT NULL,
  arm_id      INT NOT NULL,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT patient_arm_study
    FOREIGN KEY (arm_id, study_id)
    REFERENCES arm (id, study_id) ON DELETE CASCADE
);
