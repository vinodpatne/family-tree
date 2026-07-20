package com.familytree.service;

import com.familytree.entity.FamilyEntity;
import com.familytree.entity.FieldSchemaEntity;
import com.familytree.repository.FamilyRepository;
import com.familytree.repository.FieldSchemaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
@RequiredArgsConstructor
public class FamilyService {

    private final FamilyRepository familyRepository;
    private final FieldSchemaRepository fieldSchemaRepository;
    private final AuditService auditService;
    private final JdbcTemplate jdbcTemplate;

    public List<FamilyEntity> getFamiliesForUser(String userId) {
        return familyRepository.findFamiliesForUser(userId);
    }

    public Optional<FamilyEntity> getFamily(String familyId) {
        return familyRepository.findById(familyId);
    }

    @Transactional
    public FamilyEntity createFamily(String name, String userId) {
        String familyId = UUID.randomUUID().toString();
        String schemaId = UUID.randomUUID().toString();

        // Save family first (field_schemas has a FK to families.id)
        Map<String, Object> defaultSettings = Map.of(
                "photoShape", "circle",
                "genderColors", Map.of("male", "#2E86DE", "female", "#E84393", "other", "#8E44AD")
        );

        FamilyEntity family = FamilyEntity.builder()
                .id(familyId)
                .name(name)
                .createdBy(userId)
                .memberUserIds(List.of(userId))
                .roles(Map.of(userId, "owner"))
                .settings(defaultSettings)
                .fieldSchemaId(schemaId)
                .build();
        familyRepository.save(family);

        // Now clone field template into a new schema for this family
        List<Map<String, Object>> templateFields = loadTemplateFields();

        FieldSchemaEntity schema = FieldSchemaEntity.builder()
                .id(schemaId)
                .familyId(familyId)
                .fields(templateFields)
                .version(1)
                .build();
        fieldSchemaRepository.save(schema);

        auditService.log(familyId, userId, "FAMILY_CREATED", "family", familyId, null, Map.of("name", name));
        return family;
    }

    @Transactional
    public FamilyEntity updateSettings(String familyId, Map<String, Object> settings, String userId) {
        FamilyEntity family = familyRepository.findById(familyId)
                .orElseThrow(() -> new NoSuchElementException("Family not found: " + familyId));
        Map<String, Object> before = family.getSettings();
        family.setSettings(settings);
        familyRepository.save(family);
        auditService.log(familyId, userId, "SETTINGS_UPDATED", "family", familyId, before, settings);
        return family;
    }

    @Transactional
    public void deleteFamily(String familyId, String userId) {
        FamilyEntity family = familyRepository.findById(familyId)
                .orElseThrow(() -> new NoSuchElementException("Family not found: " + familyId));
        
        String role = family.getRoles().get(userId);
        if (!"owner".equals(role)) {
            throw new RuntimeException("Only owner can delete family");
        }
        
        familyRepository.deleteById(familyId);
        auditService.log(familyId, userId, "FAMILY_DELETED", "family", familyId, Map.of("name", family.getName()), null);
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> loadTemplateFields() {
        try {
            String json = jdbcTemplate.queryForObject(
                    "SELECT fields::text FROM family_tree.field_definition_templates WHERE id = 'default-template-v1'",
                    String.class);
            if (json != null) {
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                return mapper.readValue(json, List.class);
            }
        } catch (Exception e) {
            // Fall through to defaults
        }
        return List.of(
                Map.of("key", "firstName", "label", "First Name", "type", "text", "mandatory", true, "isDefault", true),
                Map.of("key", "lastName", "label", "Last Name", "type", "text", "mandatory", true, "isDefault", true)
        );
    }
}
