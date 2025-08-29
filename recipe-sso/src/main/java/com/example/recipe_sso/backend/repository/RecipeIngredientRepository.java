package com.example.recipe_sso.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.recipe_sso.backend.model.recipeingredient.RecipeIngredient;
import com.example.recipe_sso.backend.model.recipeingredient.RecipeIngredientId;

public interface RecipeIngredientRepository
        extends JpaRepository<RecipeIngredient, RecipeIngredientId> {

    List<RecipeIngredient> findByRecipeId(Long recipeId);
    List<RecipeIngredient> findByIngredientId(Long ingredientId);
}