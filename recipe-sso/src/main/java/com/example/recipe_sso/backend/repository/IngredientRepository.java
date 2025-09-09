package com.example.recipe_sso.backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.recipe_sso.backend.model.Ingredient;
import com.example.recipe_sso.backend.model.IngredientCategory;

public interface IngredientRepository extends JpaRepository<Ingredient, Long> {

    /** Autocomplete: içinde geçenlere göre (A→Z) */
    @Query("""
           select i from Ingredient i
           where lower(i.name) like lower(concat('%', :q, '%'))
           order by i.name asc
           """)
    List<Ingredient> autocomplete(@Param("q") String q, Pageable pageable);

    /** Autocomplete + kategori filtresi (A→Z) */
    @Query("""
           select i from Ingredient i
           where i.category = :cat and lower(i.name) like lower(concat('%', :q, '%'))
           order by i.name asc
           """)
    List<Ingredient> autocompleteByCategory(@Param("q") String q,
                                            @Param("cat") IngredientCategory category,
                                            Pageable pageable);

    /** 🔹 Sadece ada göre (case-insensitive) — Service bunu çağırıyor */
    Optional<Ingredient> findByNameIgnoreCase(String name);

    /** 🔹 Ad + kategoriye göre (case-insensitive) — istersen bunu kullan */
    Optional<Ingredient> findByNameIgnoreCaseAndCategory(String name, IngredientCategory category);

    /** Tüm liste alfabetik (A→Z) */
    List<Ingredient> findAllByOrderByNameAsc();

    /** Belirli kategoride alfabetik (A→Z) */
    List<Ingredient> findAllByCategoryOrderByNameAsc(IngredientCategory category);
}