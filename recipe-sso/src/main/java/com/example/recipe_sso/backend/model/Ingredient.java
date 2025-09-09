package com.example.recipe_sso.backend.model;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

@Entity
@Table(name = "ingredient")
public class Ingredient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ⚠️ unique constraint sadece name üzerinde kaldırılmalı
    // çünkü kategoriye göre aynı isim olabilir (ör. "Süt" [DAIRY], "Süt Tozu" [OTHER])
    @Column(nullable=false)
    private String name;

    @ElementCollection
    @CollectionTable(name="ingredient_alias", joinColumns=@JoinColumn(name="ingredient_id"))
    @Column(name="alias", nullable=false)
    private List<String> aliases = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private IngredientCategory category = IngredientCategory.OTHER;

    @Column(nullable=false, updatable=false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { this.createdAt = Instant.now(); }

    // --- Getters & Setters ---
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public List<String> getAliases() { return aliases; }
    public void setAliases(List<String> aliases) { this.aliases = aliases; }

    public IngredientCategory getCategory() { return category; }
    public void setCategory(IngredientCategory category) { this.category = category; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}