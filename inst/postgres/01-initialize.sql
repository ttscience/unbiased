CREATE TABLE method (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(255) NOT NULL
);

CREATE TABLE study (
  id          SERIAL PRIMARY KEY,
  identifier  VARCHAR(12) NOT NULL,
  name        VARCHAR(255) NOT NULL,
  method_id   INT NOT NULL,
  parameters  JSON,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT study_method
    FOREIGN KEY (method_id)
    REFERENCES method (id)
);

CREATE TABLE arm (
  id          SERIAL PRIMARY KEY,
  study_id    INT NOT NULL,
  name        VARCHAR(255) NOT NULL,
  ratio       INT NOT NULL DEFAULT 1,
  CONSTRAINT arm_study
    FOREIGN KEY (study_id)
    REFERENCES study (id) ON DELETE CASCADE,
  CONSTRAINT uc_arm_study
    UNIQUE (id, study_id),
  CONSTRAINT ratio_positive
    CHECK (ratio > 0)
);

CREATE TABLE stratum (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  value_type  VARCHAR(12),
  CONSTRAINT chk_value_type
    CHECK (value_type IN ('factor', 'numeric'))
);

CREATE TABLE stratum_in_study (
  stratum_id  INT NOT NULL,
  study_id    INT NOT NULL,
  CONSTRAINT fk_stratum
    FOREIGN KEY (stratum_id)
    REFERENCES stratum (id) ON DELETE CASCADE,
  CONSTRAINT fk_study
    FOREIGN KEY (study_id)
    REFERENCES study (id) ON DELETE CASCADE,
  CONSTRAINT uc_stratum_study
    UNIQUE (stratum_id, study_id)
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

-- TODO: Add trigger to check for stratum value type = 'numeric'
CREATE TABLE numeric_constraint (
  stratum_id  INT NOT NULL,
  min_value   FLOAT,
  max_value   FLOAT,
  CONSTRAINT numeric_stratum
    FOREIGN KEY (stratum_id)
    REFERENCES stratum (id) ON DELETE CASCADE,
  CONSTRAINT uc_stratum
    UNIQUE (stratum_id),
  CONSTRAINT chk_min_max
    -- NULL is ok in checks, no need to test for it
    CHECK (min_value <= max_value)
);

CREATE TABLE patient (
  id          SERIAL PRIMARY KEY,
  study_id    INT NOT NULL,
  arm_id      INT NOT NULL,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT now(),
  rand_code   VARCHAR(255),
  CONSTRAINT patient_arm_study
    FOREIGN KEY (arm_id, study_id)
    REFERENCES arm (id, study_id) ON DELETE CASCADE,
  CONSTRAINT uc_study_code
    UNIQUE (study_id, rand_code)
);


CREATE OR REPLACE FUNCTION check_fct_stratum()
RETURNS trigger AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM stratum
    -- Checks that column value is correct
    WHERE id = NEW.stratum_id AND value_type <> 'factor'
  ) THEN
    RAISE EXCEPTION 'Can''t set factor constraint for non-factor stratum.';
  END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION check_num_stratum()
RETURNS trigger AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM stratum
    -- Checks that column value is correct
    WHERE id = NEW.stratum_id AND value_type <> 'numeric'
  ) THEN
    RAISE EXCEPTION 'Can''t set numeric constraint for non-numeric stratum.';
  END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER stratum_fct_constraint
BEFORE INSERT
ON factor_constraint
FOR EACH STATEMENT
EXECUTE PROCEDURE check_fct_stratum();


CREATE TRIGGER stratum_num_constraint
BEFORE INSERT
ON numeric_constraint
FOR EACH STATEMENT
EXECUTE PROCEDURE check_num_stratum();
