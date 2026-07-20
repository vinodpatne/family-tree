package com.familytree.entity;

import io.hypersistence.utils.hibernate.type.json.JsonType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Type;
import java.util.List;
import java.util.Map;

@Entity
@Table(name = "field_schemas", schema = "family_tree")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class FieldSchemaEntity {
    @Id
    private String id;

    @Column(name = "family_id", nullable = false, unique = true)
    private String familyId;

    @Type(JsonType.class)
    @Column(name = "fields", columnDefinition = "jsonb")
    private List<Map<String, Object>> fields;

    @Column(nullable = false)
    private int version;
}
