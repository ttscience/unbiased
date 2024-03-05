-- Stratum constraint checks

CREATE FUNCTION check_fct_stratum()
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


CREATE FUNCTION check_num_stratum()
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
CREATE FUNCTION check_patient_stratum_study()
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
CREATE FUNCTION check_fct_patient()
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
CREATE FUNCTION check_num_patient()
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
