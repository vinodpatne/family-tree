package com.familytree.entity;

import io.hypersistence.utils.hibernate.type.json.JsonType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Type;
import java.time.Instant;
import java.util.Map;

@Entity
@Table(name = "audit_log", schema = "family_tree")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AuditLogEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id")
    private String familyId;

    @Column(name = "user_id")
    private String userId;

    @Column(nullable = false)
    private String action;

    @Column(name = "entity_type")
    private String entityType;

    @Column(name = "entity_id")
    private String entityId;

    @Type(JsonType.class)
    @Column(name = "before_data", columnDefinition = "jsonb")
    private Map<String, Object> beforeData;

    @Type(JsonType.class)
    @Column(name = "after_data", columnDefinition = "jsonb")
    private Map<String, Object> afterData;

    @Column(nullable = false)
    private Instant timestamp;

    @PrePersist
    void prePersist() {
        if (timestamp == null) timestamp = Instant.now();
    }
}
