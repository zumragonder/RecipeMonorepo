package com.example.recipe_sso.backend.service;

import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.recipe_sso.backend.model.Ingredient;
import com.example.recipe_sso.backend.repository.IngredientRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class IngredientService {
    private final IngredientRepository ingredientRepository;

    public List<Ingredient> autocomplete(String q, int limit) {
        Pageable pageable = PageRequest.of(0, Math.max(1, Math.min(limit, 50)));
        return ingredientRepository.autocomplete(q, pageable);
    }

    @Transactional
    public Ingredient create(String name, List<String> aliases) {
        Ingredient ingredient = new Ingredient();
        ingredient.setName(name);
        ingredient.setAliases(aliases);
        return ingredientRepository.save(ingredient);
    }
}