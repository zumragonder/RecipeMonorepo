package com.example.recipe_sso.backend.dto;

import java.util.List;

public record CreateRecipeRequest(
    String title,
    String description,
    Long authorId,          // eski kullanım (isteğe bağlı kalsın)
    String authorEmail,     // ✅ yeni alan: email ile user bulma
    List<IngredientDto> ingredients,
    String imageBase64,
    List<String> imagesBase64,
    String category
) {
    public record IngredientDto(
        Long ingredientId,
        String amount,
        String unit
    ) {}
}