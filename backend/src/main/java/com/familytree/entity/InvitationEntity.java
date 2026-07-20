package com.familytree.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

@Entity
@Table(name = "invitations", schema = "family_tree")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InvitationEntity {
    @Id
    private String id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(name = "invited_email", nullable = false)
    private String invitedEmail;

    @Column(nullable = false)
    @Builder.Default
    private String role = "viewer";

    @Column(nullable = false, unique = true)
    private String token;

    @Column(nullable = false)
    @Builder.Default
    private String status = "pending";

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }
}
