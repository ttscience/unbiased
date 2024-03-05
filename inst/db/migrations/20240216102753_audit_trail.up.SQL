CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_type TEXT NOT NULL,
    request_id UUID NOT NULL,
    study_id integer,
    endpoint_url TEXT NOT NULL,
    request_method TEXT NOT NULL,
    request_body JSONB,
    response_code integer NOT NULL,
    response_body JSONB,
    CONSTRAINT audit_log_study_id_fk
        FOREIGN KEY (study_id)
        REFERENCES study (id)
);

CREATE INDEX audit_log_study_id_idx ON audit_log (study_id);
