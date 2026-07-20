-- Seed a demo user
INSERT INTO family_tree.users (id, email, name, avatar_url) VALUES
    ('mock-owner-user', 'owner@example.com', 'Mock Owner', 'https://i.pravatar.cc/100?u=mock-owner-user');

-- Seed a demo family
INSERT INTO family_tree.families (id, name, created_by, member_user_ids, roles, settings, field_schema_id) VALUES (
    'demo-family-001',
    'Patne Family',
    'mock-owner-user',
    '["mock-owner-user"]'::jsonb,
    '{"mock-owner-user":"owner"}'::jsonb,
    '{"photoShape":"circle","genderColors":{"male":"#2E86DE","female":"#E84393","other":"#8E44AD"}}'::jsonb,
    'demo-schema-001'
);

-- Seed the field schema for this family (cloned from template)
INSERT INTO family_tree.field_schemas (id, family_id, fields, version) VALUES (
    'demo-schema-001',
    'demo-family-001',
    (SELECT fields FROM family_tree.field_definition_templates WHERE id = 'default-template-v1'),
    1
);

-- Seed demo family members
INSERT INTO family_tree.family_members (id, family_id, schema_version, data, relations, created_by, last_edited_by) VALUES
(
    'member-grandfather',
    'demo-family-001',
    1,
    '{"firstName":"Ramchandra","lastName":"Patne","gender":"male","profession":"Farmer","dob":"1940-01-15"}'::jsonb,
    '{"fatherId":null,"motherId":null,"spouseIds":["member-grandmother"],"childrenIds":["member-father","member-uncle"]}'::jsonb,
    'mock-owner-user',
    'mock-owner-user'
),
(
    'member-grandmother',
    'demo-family-001',
    1,
    '{"firstName":"Saraswati","lastName":"Patne","gender":"female","profession":"Teacher","dob":"1945-06-20"}'::jsonb,
    '{"fatherId":null,"motherId":null,"spouseIds":["member-grandfather"],"childrenIds":["member-father","member-uncle"]}'::jsonb,
    'mock-owner-user',
    'mock-owner-user'
),
(
    'member-father',
    'demo-family-001',
    1,
    '{"firstName":"Vinod","lastName":"Patne","gender":"male","profession":"Engineer","dob":"1970-03-10"}'::jsonb,
    '{"fatherId":"member-grandfather","motherId":"member-grandmother","spouseIds":["member-mother"],"childrenIds":["member-child1","member-child2"]}'::jsonb,
    'mock-owner-user',
    'mock-owner-user'
),
(
    'member-mother',
    'demo-family-001',
    1,
    '{"firstName":"Sunita","lastName":"Patne","gender":"female","profession":"Doctor","dob":"1975-08-25"}'::jsonb,
    '{"fatherId":null,"motherId":null,"spouseIds":["member-father"],"childrenIds":["member-child1","member-child2"]}'::jsonb,
    'mock-owner-user',
    'mock-owner-user'
),
(
    'member-uncle',
    'demo-family-001',
    1,
    '{"firstName":"Manoj","lastName":"Patne","gender":"male","profession":"Manager","dob":"1973-11-05"}'::jsonb,
    '{"fatherId":"member-grandfather","motherId":"member-grandmother","spouseIds":[],"childrenIds":[]}'::jsonb,
    'mock-owner-user',
    'mock-owner-user'
),
(
    'member-child1',
    'demo-family-001',
    1,
    '{"firstName":"Aarav","lastName":"Patne","gender":"male","profession":"Developer","dob":"2000-02-14"}'::jsonb,
    '{"fatherId":"member-father","motherId":"member-mother","spouseIds":[],"childrenIds":[]}'::jsonb,
    'mock-owner-user',
    'mock-owner-user'
),
(
    'member-child2',
    'demo-family-001',
    1,
    '{"firstName":"Priya","lastName":"Patne","gender":"female","profession":"Artist","dob":"2003-07-30"}'::jsonb,
    '{"fatherId":"member-father","motherId":"member-mother","spouseIds":[],"childrenIds":[]}'::jsonb,
    'mock-owner-user',
    'mock-owner-user'
);
