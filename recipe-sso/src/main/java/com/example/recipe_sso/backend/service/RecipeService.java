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

    public Optional<Recipe> get(Long id) {
        return recipeRepository.findById(id);
    }

    @Transactional
    public Recipe createRecipe(String title, String description, Long authorId, List<RecipeIngredient> items) {
        User author = userRepository.findById(authorId)
                .orElseThrow(() -> new IllegalArgumentException("author not found"));

        Recipe recipe = new Recipe();
        recipe.setTitle(title);
        recipe.setDescription(description);
        recipe.setAuthor(author);

        if (items != null) {
            for (RecipeIngredient ri : items) {
                // ingredient id dolu ise DB’den bağla
                if (ri.getIngredient() != null && ri.getIngredient().getId() != null) {
                    Ingredient ing = ingredientRepository.findById(ri.getIngredient().getId())
                            .orElseThrow(() -> new IllegalArgumentException("ingredient not found: " + ri.getIngredient().getId()));
                    ri.setIngredient(ing);
                }
                recipe.addIngredient(ri); // iki yönü de kurar
            }
        }

        return recipeRepository.save(recipe);
    }

    public Page<Recipe> suggestByIngredients(List<Long> ingredientIds, Pageable pageable) {
        if (ingredientIds == null || ingredientIds.isEmpty())
            return Page.empty(pageable);
        if (ingredientIds.size() > 10)
            throw new IllegalArgumentException("En fazla 10 malzeme seçilebilir.");
        return recipeRepository.suggestByIngredients(ingredientIds, pageable);
    }

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

    @Transactional
    public void updateRatingStats(Long recipeId, double avg, long count) {
        recipeRepository.findById(recipeId).ifPresent(r -> {
            r.setRatingAvg(BigDecimal.valueOf(avg));
            r.setRatingCount((int) count);
            r.setUpdatedAt(new Date());
            recipeRepository.save(r);
        });
    }
}