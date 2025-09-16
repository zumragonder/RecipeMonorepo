package com.example.recipe_sso.backend.service;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.recipe_sso.backend.model.Ingredient;
import com.example.recipe_sso.backend.model.Recipe;
import com.example.recipe_sso.backend.model.RecipeCategory;   // 🍽️ yeni import
import com.example.recipe_sso.backend.model.User;
import com.example.recipe_sso.backend.model.recipeingredient.RecipeIngredient;
import com.example.recipe_sso.backend.repository.IngredientRepository;
import com.example.recipe_sso.backend.repository.RecipeRepository;
import com.example.recipe_sso.backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class RecipeService {

    private final RecipeRepository recipeRepository;
    private final IngredientRepository ingredientRepository;
    private final UserRepository userRepository;

    /** 🔍 Tek tarif getir */
    public Optional<Recipe> get(Long id) {
        return recipeRepository.findById(id);
    }

    /** ➕ Yeni tarif oluştur (tek + çoklu fotoğraf + kategori destekli) */
    @Transactional
    public Recipe createRecipe(String title,
                               String description,
                               Long authorId,
                               List<RecipeIngredient> items,
                               String imageBase64,
                               List<String> imagesBase64,
                               RecipeCategory category) {   // 🍽️ kategori parametresi

        User author = userRepository.findById(authorId)
                .orElseThrow(() -> new IllegalArgumentException("author not found"));

        Recipe recipe = new Recipe();
        recipe.setTitle(title);
        recipe.setDescription(description);
        recipe.setAuthor(author);
        recipe.setCategory(category);   // 🍽️ kategori set edildi

        // 📸 Tek fotoğraf (geriye uyumluluk için)
        if (imageBase64 != null && !imageBase64.isBlank()) {
            recipe.setImageBase64(imageBase64);
        }

        // 📸 Çoklu fotoğraf (yeni)
        if (imagesBase64 != null && !imagesBase64.isEmpty()) {
            recipe.setImagesBase64(imagesBase64);
        }

        // 🥗 Malzemeler
        if (items != null) {
            for (RecipeIngredient ri : items) {
                if (ri.getIngredient() != null && ri.getIngredient().getId() != null) {
                    Ingredient ing = ingredientRepository.findById(ri.getIngredient().getId())
                            .orElseThrow(() -> new IllegalArgumentException(
                                    "ingredient not found: " + ri.getIngredient().getId()));
                    ri.setIngredient(ing);
                }
                recipe.addIngredient(ri);
            }
        }

        return recipeRepository.save(recipe);
    }

    /** ➕ Yeni tarif oluştur (authorEmail ile) */
    @Transactional
    public Recipe createRecipeByEmail(String title,
                                      String description,
                                      String authorEmail,
                                      List<RecipeIngredient> items,
                                      String imageBase64,
                                      List<String> imagesBase64,
                                      RecipeCategory category) {

        User author = userRepository.findByEmail(authorEmail)
                .orElseThrow(() -> new IllegalArgumentException("author not found with email: " + authorEmail));

        Recipe recipe = new Recipe();
        recipe.setTitle(title);
        recipe.setDescription(description);
        recipe.setAuthor(author);
        recipe.setCategory(category);

        // 📸 Tek fotoğraf
        if (imageBase64 != null && !imageBase64.isBlank()) {
            recipe.setImageBase64(imageBase64);
        }

        // 📸 Çoklu fotoğraf
        if (imagesBase64 != null && !imagesBase64.isEmpty()) {
            recipe.setImagesBase64(imagesBase64);
        }

        // 🥗 Malzemeler
        if (items != null) {
            for (RecipeIngredient ri : items) {
                if (ri.getIngredient() != null && ri.getIngredient().getId() != null) {
                    Ingredient ing = ingredientRepository.findById(ri.getIngredient().getId())
                            .orElseThrow(() -> new IllegalArgumentException(
                                    "ingredient not found: " + ri.getIngredient().getId()));
                    ri.setIngredient(ing);
                }
                recipe.addIngredient(ri);
            }
        }

        return recipeRepository.save(recipe);
    }

    /** 📊 Malzeme önerisine göre tarifler (en çok eşleşenleri bulur) */
    public Page<Recipe> suggestByIngredients(List<Long> ingredientIds, Pageable pageable) {
        if (ingredientIds == null || ingredientIds.isEmpty())
            return Page.empty(pageable);
        if (ingredientIds.size() > 10)
            throw new IllegalArgumentException("En fazla 10 malzeme seçilebilir.");
        return recipeRepository.suggestByIngredients(ingredientIds, pageable);
    }

    /** 📊 Tüm seçilen malzemeleri içeren tarifler */
    public Page<Recipe> findByAllIngredients(List<Long> ingredientIds, Pageable pageable) {
        if (ingredientIds == null || ingredientIds.isEmpty())
            return Page.empty(pageable);
        if (ingredientIds.size() > 10)
            throw new IllegalArgumentException("En fazla 10 malzeme seçilebilir.");
        return recipeRepository.findByAllIngredients(ingredientIds, ingredientIds.size(), pageable);
    }

    /** 🔎 Tarif arama */
    public Page<Recipe> search(String name, Integer minRating, Pageable pageable) {
        boolean hasName = name != null && !name.isBlank();
        boolean hasMin = minRating != null;

        if (hasName && hasMin) {
            return recipeRepository.findByTitleContainingIgnoreCaseAndRatingAvgGreaterThanEqual(
                    name, BigDecimal.valueOf(minRating), pageable);
        } else if (hasName) {
            return recipeRepository.findByTitleContainingIgnoreCase(name, pageable);
        } else if (hasMin) {
            return recipeRepository.findByRatingAvgGreaterThanEqual(BigDecimal.valueOf(minRating), pageable);
        } else {
            return recipeRepository.findAll(pageable);
        }
    }

    /** ⭐ Rating güncelleme */
    @Transactional
    public void updateRatingStats(Long recipeId, double avg, long count) {
        recipeRepository.findById(recipeId).ifPresent(r -> {
            r.setRatingAvg(BigDecimal.valueOf(avg));
            r.setRatingCount((int) count);
            r.setUpdatedAt(new Date());
            recipeRepository.save(r);
        });
    }

    /** 🍽️ Kategoriye göre tarifleri getir */
    public List<Recipe> getByCategory(RecipeCategory category) {
        return recipeRepository.findByCategory(category);
    }

    /** 👨‍🍳 Şefe göre tarifleri getir */
    public List<Recipe> getByAuthor(Long authorId) {
        return recipeRepository.findByAuthorId(authorId);
    }
}