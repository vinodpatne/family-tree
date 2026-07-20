package com.familytree.service;

import com.familytree.entity.FieldSchemaEntity;
import com.familytree.repository.FieldSchemaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
@RequiredArgsConstructor
public class FieldSchemaService {

    private final FieldSchemaRepository fieldSchemaRepository;
    private final AuditService auditService;

    public Optional<FieldSchemaEntity> getSchemaByFamilyId(String familyId) {
        return fieldSchemaRepository.findByFamilyId(familyId);
    }

    public Optional<FieldSchemaEntity> getSchema(String schemaId) {
        return fieldSchemaRepository.findById(schemaId);
    }

    @Transactional
    public FieldSchemaEntity updateFields(String familyId, List<Map<String, Object>> fields, String userId) {
        FieldSchemaEntity schema = fieldSchemaRepository.findByFamilyId(familyId)
                .orElseThrow(() -> new NoSuchElementException("Schema not found for family: " + familyId));

        schema.setFields(fields);
        schema.setVersion(schema.getVersion() + 1);
        fieldSchemaRepository.save(schema);

        auditService.log(familyId, userId, "SCHEMA_UPDATED", "field_schema", schema.getId(), null, Map.of("version", schema.getVersion()));
        return schema;
    }
}
