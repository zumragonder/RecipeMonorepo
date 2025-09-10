package com.example.recipe_sso.backend.dto;

import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

import com.example.recipe_sso.backend.model.Recipe;

public class RecipeDto {
    public Long id;
    public String title;
    public String description;
    public String authorEmail;
    public Date createdAt;
    public List<RecipeIngredientDto> ingredients;

    public static RecipeDto fromEntity(Recipe r) {
        RecipeDto dto = new RecipeDto();
        dto.id = r.getId();
        dto.title = r.getTitle();
        dto.description = r.getDescription();
        dto.authorEmail = r.getAuthor() != null ? r.getAuthor().getEmail() : null;
        dto.createdAt = r.getCreatedAt();
        dto.ingredients = r.getIngredients()
            .stream()
            .map(RecipeIngredientDto::fromEntity)
            .collect(Collectors.toList());
        return dto;
    }
}