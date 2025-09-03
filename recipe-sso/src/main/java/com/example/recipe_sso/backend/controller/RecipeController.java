package com.example.recipe_sso.backend.controller;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.recipe_sso.backend.dto.CreateRecipeRequest;
import com.example.recipe_sso.backend.model.Ingredient;
import com.example.recipe_sso.backend.model.Recipe;
import com.example.recipe_sso.backend.model.recipeingredient.RecipeIngredient;
import com.example.recipe_sso.backend.service.RecipeService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/recipes")
@RequiredArgsConstructor
public class RecipeController {

    private final RecipeService recipeService;

    @GetMapping("/{id}")
    public Optional<Recipe> get(@PathVariable Long id) {
        return recipeService.get(id);
    }

    @PostMapping
    public Recipe create(@RequestBody CreateRecipeRequest req) {
        // DTO -> entity bağlama
        List<RecipeIngredient> items = new ArrayList<>();
        if (req.ingredients() != null) {
            for (var d : req.ingredients()) {
                Ingredient ing = new Ingredient();
                ing.setId(d.ingredientId());
                RecipeIngredient ri = new RecipeIngredient();
                ri.setIngredient(ing);
                ri.setAmount(d.amount());
                ri.setUnit(d.unit());
                items.add(ri);
            }
        }
        return recipeService.createRecipe(req.title(), req.description(), req.authorId(), items);
    }

    @GetMapping("/suggest")
    public Page<Recipe> suggest(@RequestParam List<Long> ingredientIds,
                                @RequestParam(defaultValue = "0") int page,
                                @RequestParam(defaultValue = "20") int size) {
        return recipeService.suggestByIngredients(ingredientIds, PageRequest.of(page, size));
    }

    @GetMapping
    public Page<Recipe> search(@RequestParam(required = false) String name,
                               @RequestParam(required = false) Integer minRating,
                               @RequestParam(defaultValue = "0") int page,
                               @RequestParam(defaultValue = "20") int size) {
        return recipeService.search(name, minRating, PageRequest.of(page, size));
    }

  
}