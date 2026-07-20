package com.familytree.controller;

import com.familytree.entity.FieldSchemaEntity;
import com.familytree.entity.UserEntity;
import com.familytree.service.FieldSchemaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/families/{familyId}/schema")
@RequiredArgsConstructor
public class FieldSchemaController {

    private final FieldSchemaService fieldSchemaService;

    @GetMapping
    public ResponseEntity<FieldSchemaEntity> getSchema(@PathVariable String familyId) {
        return fieldSchemaService.getSchemaByFamilyId(familyId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/fields")
    @SuppressWarnings("unchecked")
    public ResponseEntity<FieldSchemaEntity> updateFields(
            @PathVariable String familyId,
            @RequestBody Map<String, Object> body,
            @AuthenticationPrincipal UserEntity user) {
        List<Map<String, Object>> fields = (List<Map<String, Object>>) body.get("fields");
        if (fields == null) {
            return ResponseEntity.badRequest().build();
        }
        FieldSchemaEntity updated = fieldSchemaService.updateFields(familyId, fields, user.getId());
        return ResponseEntity.ok(updated);
    }
}
