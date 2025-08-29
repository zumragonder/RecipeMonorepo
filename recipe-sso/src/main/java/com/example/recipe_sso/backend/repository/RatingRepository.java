package com.example.recipe_sso.backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.recipe_sso.backend.model.rating.Rating;
import com.example.recipe_sso.backend.model.rating.RatingId;

public interface RatingRepository extends JpaRepository<Rating, RatingId> {
    // user.id ve recipe.id alanlarından
    Optional<Rating> findByUser_IdAndRecipe_Id(Long userId, Long recipeId);

    @Query("select avg(r.score) from Rating r where r.recipe.id = :recipeId")
    Double calcAvg(@Param("recipeId") Long recipeId);

    long countByRecipe_Id(Long recipeId);
}