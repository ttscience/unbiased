CREATE EXTENSION temporal_tables;

CREATE TABLE method (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  sys_period  TSTZRANGE NOT NULL
);

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
    CHECK (fct_value IS NULL OR num_value IS NULL)
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


CREATE TRIGGER stratum_fct_constraint
BEFORE INSERT ON factor_constraint
FOR EACH ROW
EXECUTE PROCEDURE check_fct_stratum();


CREATE TRIGGER stratum_num_constraint
BEFORE INSERT ON numeric_constraint
FOR EACH ROW
EXECUTE PROCEDURE check_num_stratum();

-- Patient stratum value checks

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


CREATE TRIGGER patient_stratum_study_constraint
BEFORE INSERT ON patient_stratum
FOR EACH ROW
EXECUTE PROCEDURE check_patient_stratum_study();


CREATE TRIGGER patient_fct_constraint
BEFORE INSERT ON patient_stratum
FOR EACH ROW
EXECUTE PROCEDURE check_fct_patient();


CREATE TRIGGER patient_num_constraint
BEFORE INSERT ON patient_stratum
FOR EACH ROW
EXECUTE PROCEDURE check_num_patient();
