package com.example.recipe_sso.backend.dto;

import java.util.List;

public record CreateRecipeRequest(
    String title,
    String description,
    Long authorId,
    List<IngredientDto> ingredients
) {
    public record IngredientDto(
        Long ingredientId,
        String amount,
        String unit
    ) {}
}