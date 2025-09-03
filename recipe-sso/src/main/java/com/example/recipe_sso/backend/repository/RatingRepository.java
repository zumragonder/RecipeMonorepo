package com.example.recipe_sso.backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.recipe_sso.backend.model.rating.Rating;

public interface RatingRepository extends JpaRepository<Rating, Long> {

    // userId + recipeId ile tek kaydı bul
    Optional<Rating> findByUserIdAndRecipeId(Long userId, Long recipeId);

    // Belirli bir recipe için ortalama puan
    @Query("select avg(r.value) from Rating r where r.recipeId = :recipeId")
    Double calcAvg(@Param("recipeId") Long recipeId);

    // Belirli bir recipe için oy sayısı
    long countByRecipeId(Long recipeId);
}