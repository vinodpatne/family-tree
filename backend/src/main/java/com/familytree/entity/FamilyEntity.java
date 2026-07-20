package com.familytree.entity;

import io.hypersistence.utils.hibernate.type.json.JsonType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Type;
import java.time.Instant;
import java.util.List;
import java.util.Map;

@Entity
@Table(name = "families", schema = "family_tree")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class FamilyEntity {
    @Id
    private String id;

    @Column(nullable = false)
    private String name;

    @Column(name = "created_by", nullable = false)
    private String createdBy;

    @Type(JsonType.class)
    @Column(name = "member_user_ids", columnDefinition = "jsonb")
    private List<String> memberUserIds;

    @Type(JsonType.class)
    @Column(name = "roles", columnDefinition = "jsonb")
    private Map<String, String> roles;

    @Type(JsonType.class)
    @Column(name = "settings", columnDefinition = "jsonb")
    private Map<String, Object> settings;

    @Column(name = "field_schema_id")
    private String fieldSchemaId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }
}
