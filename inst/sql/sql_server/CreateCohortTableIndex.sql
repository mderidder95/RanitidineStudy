-- Add an index to the @cohort_table table to help with performance in the next steps
CREATE INDEX idx_cohort_def_id ON @cohort_database_schema.@cohort_table (cohort_definition_id);
CREATE INDEX idx_cohort_subj ON @cohort_database_schema.@cohort_table (subject_id);
CREATE INDEX idx_cohort_start ON @cohort_database_schema.@cohort_table (cohort_start_date);
CREATE INDEX idx_cohort_end ON @cohort_database_schema.@cohort_table (cohort_end_date);
