package com.example.recipe_sso.backend.repository;

import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.recipe_sso.backend.model.Ingredient;

public interface IngredientRepository extends JpaRepository<Ingredient, Long> {
    @Query("""
           select i from Ingredient i
           where lower(i.name) like lower(concat('%', :q, '%'))
           order by i.name asc
           """)
    List<Ingredient> autocomplete(@Param("q") String q, Pageable pageable);
}