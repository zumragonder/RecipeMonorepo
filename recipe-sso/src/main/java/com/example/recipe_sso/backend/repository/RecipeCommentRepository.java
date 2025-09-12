package com.example.recipe_sso.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.recipe_sso.backend.model.RecipeComment;

public interface RecipeCommentRepository extends JpaRepository<RecipeComment, Long> {
    List<RecipeComment> findByRecipeIdOrderByCreatedAtDesc(Long recipeId);
}