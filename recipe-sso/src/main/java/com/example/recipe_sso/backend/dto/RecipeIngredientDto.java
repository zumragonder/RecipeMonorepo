package com.example.recipe_sso.backend.dto;

import com.example.recipe_sso.backend.model.recipeingredient.RecipeIngredient;

public class RecipeIngredientDto {
    public Long ingredientId;
    public String ingredientName;
    public String ingredientCategory;
    public String amount;
    public String unit;

    public static RecipeIngredientDto fromEntity(RecipeIngredient ri) {
        RecipeIngredientDto dto = new RecipeIngredientDto();
        if (ri.getIngredient() != null) {
            dto.ingredientId = ri.getIngredient().getId();
            dto.ingredientName = ri.getIngredient().getName();
            dto.ingredientCategory = ri.getIngredient().getCategory().name();
        }
        dto.amount = ri.getAmount();
        dto.unit = ri.getUnit();
        return dto;
    }
}