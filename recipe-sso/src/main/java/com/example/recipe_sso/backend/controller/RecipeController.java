package com.example.recipe_sso.backend.controller;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
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

    /** 🔍 Tek tarif getir (DTO döner) */
    @GetMapping("/{id}")
    public ResponseEntity<RecipeDto> get(@PathVariable Long id) {
        return recipeService.get(id)
                .map(r -> ResponseEntity.ok(RecipeDto.fromEntity(r)))
                .orElse(ResponseEntity.notFound().build());
    }

    /** ➕ Yeni tarif oluştur (DTO döner) */
    @PostMapping
    public ResponseEntity<RecipeDto> create(@RequestBody CreateRecipeRequest req) {
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

        Recipe recipe = recipeService.createRecipe(
                req.title(),
                req.description(),
                req.authorId(),
                items,
                req.imageBase64(),   // 📸 tekli (geriye uyumluluk)
                req.imagesBase64()   // 📸 çoklu foto
        );
        return ResponseEntity.ok(RecipeDto.fromEntity(recipe));
    }

    /** 📊 Malzemelere göre önerilen tarifler */
    @GetMapping("/suggest")
    public Page<RecipeDto> suggest(@RequestParam List<Long> ingredientIds,
                                   @RequestParam(defaultValue = "0") int page,
                                   @RequestParam(defaultValue = "20") int size) {
        return recipeService.suggestByIngredients(ingredientIds, PageRequest.of(page, size))
                .map(RecipeDto::fromEntity);
    }

    /** 🔎 Arama */
    @GetMapping
    public Page<RecipeDto> search(@RequestParam(required = false) String name,
                                  @RequestParam(required = false) Integer minRating,
                                  @RequestParam(defaultValue = "0") int page,
                                  @RequestParam(defaultValue = "20") int size) {
        return recipeService.search(name, minRating, PageRequest.of(page, size))
                .map(RecipeDto::fromEntity);
    }

    // ---- DTO’lar ----
    public static class RecipeDto {
        public Long id;
        public String title;
        public String description;
        public String authorEmail;
        public String imageBase64;             // 📸 tekli
        public List<String> imagesBase64;      // 📸 çoklu
        public List<IngredientLineDto> ingredients = new ArrayList<>();

        public static RecipeDto fromEntity(Recipe r) {
            RecipeDto dto = new RecipeDto();
            dto.id = r.getId();
            dto.title = r.getTitle();
            dto.description = r.getDescription();
            dto.authorEmail = r.getAuthor() != null ? r.getAuthor().getEmail() : null;
            dto.imageBase64 = r.getImageBase64();
            dto.imagesBase64 = r.getImagesBase64(); // 📸 çoklu set et

            if (r.getIngredients() != null) {
                for (RecipeIngredient ri : r.getIngredients()) {
                    dto.ingredients.add(IngredientLineDto.fromEntity(ri));
                }
            }
            return dto;
        }
    }

    public static class IngredientLineDto {
        public Long id;
        public String name;
        public String amount;
        public String unit;

        public static IngredientLineDto fromEntity(RecipeIngredient ri) {
            IngredientLineDto d = new IngredientLineDto();
            if (ri.getIngredient() != null) {
                d.id = ri.getIngredient().getId();
                d.name = ri.getIngredient().getName();
            }
            d.amount = ri.getAmount();
            d.unit = ri.getUnit();
            return d;
        }
    }
}