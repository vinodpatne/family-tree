package com.familytree.service;

import com.familytree.entity.InvitationEntity;
import com.familytree.repository.InvitationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InvitationService {

    private final InvitationRepository invitationRepository;
    private final AuditService auditService;

    public List<String> getPendingInvites(String familyId) {
        return invitationRepository.findByFamilyIdAndStatus(familyId, "pending")
                .stream()
                .map(InvitationEntity::getInvitedEmail)
                .collect(Collectors.toList());
    }

    @Transactional
    public InvitationEntity inviteCollaborator(String familyId, String email, String role, String userId) {
        InvitationEntity invite = InvitationEntity.builder()
                .id(UUID.randomUUID().toString())
                .familyId(familyId)
                .invitedEmail(email)
                .role(role != null ? role : "viewer")
                .token(UUID.randomUUID().toString())
                .status("pending")
                .build();
        invitationRepository.save(invite);

        auditService.log(familyId, userId, "INVITE_SENT", "invitation", invite.getId(), null,
                java.util.Map.of("email", email, "role", invite.getRole()));
        return invite;
    }
}
