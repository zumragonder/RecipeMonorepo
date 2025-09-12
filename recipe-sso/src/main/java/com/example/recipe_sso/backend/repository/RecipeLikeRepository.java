package com.example.recipe_sso.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.recipe_sso.backend.model.RecipeLike;

public interface RecipeLikeRepository extends JpaRepository<RecipeLike, Long> {
    boolean existsByRecipeIdAndUserId(Long recipeId, Long userId);
    long countByRecipeId(Long recipeId);
    void deleteByRecipeIdAndUserId(Long recipeId, Long userId);
}