-- Schema init
CREATE SCHEMA IF NOT EXISTS family_tree;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE, CREATE ON SCHEMA family_tree TO family_tree_app_user;
ALTER USER family_tree_app_user SET search_path TO family_tree, public;

-- Users
CREATE TABLE family_tree.users (
    id          VARCHAR(36) PRIMARY KEY,
    email       VARCHAR(255) NOT NULL UNIQUE,
    name        VARCHAR(255) NOT NULL,
    avatar_url  TEXT,
    google_id   VARCHAR(255) UNIQUE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Families
CREATE TABLE family_tree.families (
    id              VARCHAR(36) PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    created_by      VARCHAR(36) NOT NULL REFERENCES family_tree.users(id),
    member_user_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    roles           JSONB NOT NULL DEFAULT '{}'::jsonb,
    settings        JSONB NOT NULL DEFAULT '{}'::jsonb,
    field_schema_id VARCHAR(36),
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_families_created_by ON family_tree.families(created_by);

-- Field Schemas (one per family)
CREATE TABLE family_tree.field_schemas (
    id        VARCHAR(36) PRIMARY KEY,
    family_id VARCHAR(36) NOT NULL UNIQUE REFERENCES family_tree.families(id) ON DELETE CASCADE,
    fields    JSONB NOT NULL DEFAULT '[]'::jsonb,
    version   INT NOT NULL DEFAULT 1
);

-- Field Definition Template (global, seeded)
CREATE TABLE family_tree.field_definition_templates (
    id      VARCHAR(64) PRIMARY KEY,
    version INT NOT NULL DEFAULT 1,
    fields  JSONB NOT NULL DEFAULT '[]'::jsonb
);

-- Family Members
CREATE TABLE family_tree.family_members (
    id              VARCHAR(36) PRIMARY KEY,
    family_id       VARCHAR(36) NOT NULL REFERENCES family_tree.families(id) ON DELETE CASCADE,
    schema_version  INT NOT NULL DEFAULT 1,
    data            JSONB NOT NULL DEFAULT '{}'::jsonb,
    photo_base64    TEXT,
    relations       JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_by      VARCHAR(36) NOT NULL,
    last_edited_by  VARCHAR(36) NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_family_members_family_id ON family_tree.family_members(family_id);

-- Invitations
CREATE TABLE family_tree.invitations (
    id            VARCHAR(36) PRIMARY KEY,
    family_id     VARCHAR(36) NOT NULL REFERENCES family_tree.families(id) ON DELETE CASCADE,
    invited_email VARCHAR(255) NOT NULL,
    role          VARCHAR(20) NOT NULL DEFAULT 'viewer',
    token         VARCHAR(255) NOT NULL UNIQUE,
    status        VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_invitations_email_family ON family_tree.invitations(invited_email, family_id);

-- Audit Log
CREATE TABLE family_tree.audit_log (
    id          BIGSERIAL PRIMARY KEY,
    family_id   VARCHAR(36),
    user_id     VARCHAR(36),
    action      VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id   VARCHAR(36),
    before_data JSONB,
    after_data  JSONB,
    timestamp   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_audit_log_family_ts ON family_tree.audit_log(family_id, timestamp DESC);
