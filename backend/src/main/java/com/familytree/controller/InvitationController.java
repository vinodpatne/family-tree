package com.familytree.controller;

import com.familytree.entity.InvitationEntity;
import com.familytree.entity.UserEntity;
import com.familytree.service.InvitationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/families/{familyId}/invite")
@RequiredArgsConstructor
public class InvitationController {

    private final InvitationService invitationService;

    @GetMapping
    public ResponseEntity<List<String>> getPendingInvites(@PathVariable String familyId) {
        return ResponseEntity.ok(invitationService.getPendingInvites(familyId));
    }

    @PostMapping
    public ResponseEntity<InvitationEntity> invite(
            @PathVariable String familyId,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserEntity user) {
        String email = body.get("email");
        String role = body.getOrDefault("role", "viewer");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        InvitationEntity invite = invitationService.inviteCollaborator(familyId, email, role, user.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(invite);
    }
}
