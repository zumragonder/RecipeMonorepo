package com.example.recipe_sso.backend.model;

public record RecipeLikeResponse(
    boolean liked,   // şu anki kullanıcının durumu
    long likeCount,  // toplam beğeni
    Long recipeId,
    String message
) {}
