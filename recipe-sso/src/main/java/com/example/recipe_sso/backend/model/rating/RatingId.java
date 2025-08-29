package com.example.recipe_sso.backend.model.rating;

import java.io.Serializable;
import java.util.Objects;

import jakarta.persistence.Embeddable;

@Embeddable
public class RatingId implements Serializable {
    private Long userId;
    private Long recipeId;

    public RatingId() {}
    public RatingId(Long userId, Long recipeId) {
        this.userId = userId; this.recipeId = recipeId;
    }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getRecipeId() { return recipeId; }
    public void setRecipeId(Long recipeId) { this.recipeId = recipeId; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof RatingId that)) return false;
        return Objects.equals(userId, that.userId) &&
               Objects.equals(recipeId, that.recipeId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, recipeId);
    }
}