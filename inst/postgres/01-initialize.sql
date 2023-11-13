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
  CONSTRAINT UC_arm_study
    UNIQUE (id, study_id)
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
