package com.example.recipe_sso.backend.repository;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.recipe_sso.backend.model.Recipe;
import com.example.recipe_sso.backend.model.RecipeCategory;

public interface RecipeRepository extends JpaRepository<Recipe, Long> {

    List<Recipe> findTop50ByTitleIgnoreCaseContainingOrderByTitleAsc(String name);

    List<Recipe> findByRatingAvgGreaterThanEqualOrderByRatingAvgDesc(BigDecimal min);

    Page<Recipe> findByTitleContainingIgnoreCase(String name, Pageable pageable);
    Page<Recipe> findByRatingAvgGreaterThanEqual(BigDecimal min, Pageable pageable);
    Page<Recipe> findByTitleContainingIgnoreCaseAndRatingAvgGreaterThanEqual(String name, BigDecimal min, Pageable pageable);

    // FS-06/07: ingredient eşleşme sayısına göre öneri (tie: rating_avg)
    @Query(
      value = """
        SELECT r.*
        FROM recipes r
        JOIN recipe_ingredient ri ON ri.recipe_id = r.id
        WHERE ri.ingredient_id IN (:ingredientIds)
        GROUP BY r.id
        ORDER BY COUNT(ri.ingredient_id) DESC, r.rating_avg DESC NULLS LAST
      """,
      countQuery = """
        SELECT COUNT(*) FROM (
          SELECT r.id
          FROM recipes r
          JOIN recipe_ingredient ri ON ri.recipe_id = r.id
          WHERE ri.ingredient_id IN (:ingredientIds)
          GROUP BY r.id
        ) t
      """,
      nativeQuery = true
    )
    Page<Recipe> suggestByIngredients(@Param("ingredientIds") List<Long> ingredientIds, Pageable pageable);

    // ✅ Yeni eklenen method: kategoriye göre filtreleme
    List<Recipe> findByCategory(RecipeCategory category);

    // ✅ Yeni eklenen method: şefin (author) tariflerini bul
    List<Recipe> findByAuthorId(Long authorId);

        // ✅ Tüm seçilen malzemeleri içeren tarifler
    @Query(
      value = """
        SELECT r.*
        FROM recipes r
        JOIN recipe_ingredient ri ON ri.recipe_id = r.id
        WHERE ri.ingredient_id IN (:ingredientIds)
        GROUP BY r.id
        HAVING COUNT(DISTINCT ri.ingredient_id) = :ingredientCount
        ORDER BY r.rating_avg DESC NULLS LAST
      """,
      countQuery = """
        SELECT COUNT(*) FROM (
          SELECT r.id
          FROM recipes r
          JOIN recipe_ingredient ri ON ri.recipe_id = r.id
          WHERE ri.ingredient_id IN (:ingredientIds)
          GROUP BY r.id
          HAVING COUNT(DISTINCT ri.ingredient_id) = :ingredientCount
        ) t
      """,
      nativeQuery = true
    )
    Page<Recipe> findByAllIngredients(
        @Param("ingredientIds") List<Long> ingredientIds,
        @Param("ingredientCount") long ingredientCount,
        Pageable pageable
    );
}