package com.familytree.controller;

import com.familytree.entity.FamilyEntity;
import com.familytree.entity.UserEntity;
import com.familytree.service.FamilyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/families")
@RequiredArgsConstructor
public class FamilyController {

    private final FamilyService familyService;

    @GetMapping
    public ResponseEntity<List<FamilyEntity>> getFamilies(@AuthenticationPrincipal UserEntity user) {
        return ResponseEntity.ok(familyService.getFamiliesForUser(user.getId()));
    }

    @PostMapping
    public ResponseEntity<FamilyEntity> createFamily(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserEntity user) {
        String name = body.get("name");
        if (name == null || name.isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        FamilyEntity family = familyService.createFamily(name, user.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(family);
    }

    @GetMapping("/{familyId}")
    public ResponseEntity<FamilyEntity> getFamily(@PathVariable String familyId) {
        return familyService.getFamily(familyId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{familyId}/settings")
    public ResponseEntity<FamilyEntity> updateSettings(
            @PathVariable String familyId,
            @RequestBody Map<String, Object> settings,
            @AuthenticationPrincipal UserEntity user) {
        FamilyEntity updated = familyService.updateSettings(familyId, settings, user.getId());
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{familyId}")
    public ResponseEntity<Void> deleteFamily(@PathVariable String familyId, @AuthenticationPrincipal UserEntity user) {
        familyService.deleteFamily(familyId, user.getId());
        return ResponseEntity.noContent().build();
    }
}
