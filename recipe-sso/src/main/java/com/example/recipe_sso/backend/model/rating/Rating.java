package com.example.recipe_sso.backend.model.rating;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;

@Entity
@IdClass(RatingId.class)
public class Rating {

    @Id
    private Long userId;

    @Id
    private Long recipeId;

    private Integer value;

    // Getters and setters
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getRecipeId() { return recipeId; }
    public void setRecipeId(Long recipeId) { this.recipeId = recipeId; }

    public Integer getValue() { return value; }
    public void setValue(Integer value) { this.value = value; }
}