package com.familytree.entity;

import io.hypersistence.utils.hibernate.type.json.JsonType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Type;
import java.time.Instant;
import java.util.Map;

@Entity
@Table(name = "family_members", schema = "family_tree")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class FamilyMemberEntity {
    @Id
    private String id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(name = "schema_version", nullable = false)
    private int schemaVersion;

    @Type(JsonType.class)
    @Column(name = "data", columnDefinition = "jsonb")
    private Map<String, Object> data;

    @Column(name = "photo_base64", columnDefinition = "TEXT")
    private String photoBase64;

    @Type(JsonType.class)
    @Column(name = "relations", columnDefinition = "jsonb")
    private Map<String, Object> relations;

    @Column(name = "created_by", nullable = false)
    private String createdBy;

    @Column(name = "last_edited_by", nullable = false)
    private String lastEditedBy;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }
}
