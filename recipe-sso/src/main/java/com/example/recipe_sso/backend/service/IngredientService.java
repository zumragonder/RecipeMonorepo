package com.example.recipe_sso.backend.service;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.recipe_sso.backend.model.Ingredient;
import com.example.recipe_sso.backend.model.IngredientCategory;
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

    /** Yeni create: kategori parametresiyle */
    @Transactional
    public Ingredient create(String name, List<String> aliases, IngredientCategory category) {
        final String norm = name == null ? "" : name.trim();
        if (norm.isBlank()) throw new IllegalArgumentException("name is blank");

        // Zaten varsa yukarıdaki controller 409 döndürüyor ama idempotent olsun diye yine kontrol edelim
        Optional<Ingredient> existing = ingredientRepository.findByNameIgnoreCase(norm);
        if (existing.isPresent()) return existing.get();

        Ingredient ing = new Ingredient();
        ing.setName(norm);
        ing.setAliases(cleanAliases(aliases));
        ing.setCategory(category == null ? IngredientCategory.OTHER : category);
        return ingredientRepository.save(ing);
    }

    /** Alfabetik tümü */
    public List<Ingredient> findAll() {
        return ingredientRepository.findAllByOrderByNameAsc();
    }

    /** Kategoriye göre alfabetik */
    public List<Ingredient> findAllByCategory(IngredientCategory category) {
        return ingredientRepository.findAllByCategoryOrderByNameAsc(category);
    }

   public Optional<Ingredient> findByNameIgnoreCase(String name) {
    return ingredientRepository.findByNameIgnoreCase(name);
}

    // ---- helpers ----
    private List<String> cleanAliases(List<String> aliases) {
        if (aliases == null) return List.of();
        return aliases.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .distinct()
                .collect(Collectors.toList());
    }
}