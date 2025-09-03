package com.example.recipe_sso.backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
        // (Opsiyonel) 1-5 aralığı gibi bir kuralın varsa kontrol et
        if (score < 1 || score > 5) {
            throw new IllegalArgumentException("score must be between 1 and 5");
        }

        // Aynı kullanıcının aynı tarife ikinci kez oy vermesini engelle
        if (ratingRepository.findByUserIdAndRecipeId(userId, recipeId).isPresent()) {
            throw new IllegalStateException("User already rated this recipe");
        }

        // Varlık kontrolleri (entity fetch etmeye gerek yok)
        if (!recipeRepository.existsById(recipeId)) {
            throw new IllegalArgumentException("recipe not found");
        }
        if (!userRepository.existsById(userId)) {
            throw new IllegalArgumentException("user not found");
        }

        // Kaydı oluştur
        Rating rating = new Rating();
        rating.setRecipeId(recipeId);
        rating.setUserId(userId);
        rating.setValue(score);
        ratingRepository.save(rating);

        // İstatistikleri güncelle
        Double avg = ratingRepository.calcAvg(recipeId);
        long count = ratingRepository.countByRecipeId(recipeId);
        recipeService.updateRatingStats(recipeId, (avg != null ? avg : 0.0), count);

        return rating;
    }
}