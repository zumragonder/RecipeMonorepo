package com.example.recipe_sso.backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.recipe_sso.backend.model.Recipe;
import com.example.recipe_sso.backend.model.User;
import com.example.recipe_sso.backend.model.rating.Rating;
import com.example.recipe_sso.backend.repository.RatingRepository;
import com.example.recipe_sso.backend.repository.RecipeRepository;
import com.example.recipe_sso.backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class RatingService {
    private final RatingRepository ratingRepository;
    private final RecipeRepository recipeRepository;
    private final UserRepository userRepository;
    private final RecipeService recipeService;

    @Transactional
    public Rating rate(Long recipeId, Long userId, int score) {
        if (ratingRepository.findByUser_IdAndRecipe_Id(userId, recipeId).isPresent()) {
            throw new IllegalStateException("User already rated this recipe");
        }

        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("recipe not found"));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));

        Rating rating = new Rating();
        rating.setRecipeId(recipe.getId());    
        rating.setUserId(user.getId());        
        rating.setValue(score);               
        ratingRepository.save(rating);

        double avg = ratingRepository.calcAvg(recipeId);
        long count = ratingRepository.countByRecipe_Id(recipeId);
        recipeService.updateRatingStats(recipeId, avg, count);

        return rating;
    }
}