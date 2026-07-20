package com.familytree.repository;

import com.familytree.entity.InvitationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface InvitationRepository extends JpaRepository<InvitationEntity, String> {
    List<InvitationEntity> findByFamilyIdAndStatus(String familyId, String status);
    List<InvitationEntity> findByInvitedEmailAndStatus(String email, String status);
    Optional<InvitationEntity> findByToken(String token);
}
