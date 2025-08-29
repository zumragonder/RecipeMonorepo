package com.example.recipe_sso.backend.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.recipe_sso.backend.model.Ingredient;
import com.example.recipe_sso.backend.service.IngredientService;

import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/ingredients")
@RequiredArgsConstructor
public class IngredientController {

    private final IngredientService ingredientService;

    /** FS-04: Autocomplete arama */
    @GetMapping("/autocomplete")
    public List<IngredientDto> autocomplete(
            @RequestParam("q") @NotBlank String q,
            @RequestParam(defaultValue = "10") int limit) {

        List<Ingredient> items = ingredientService.autocomplete(q, limit);
        return items.stream()
                .map(i -> new IngredientDto(i.getId(), i.getName(), i.getAliases()))
                .toList();
    }

    /** (Opsiyonel admin) yeni ingredient ekleme */
    @PostMapping
    // @PreAuthorize("hasRole('ADMIN')")
    public IngredientDto create(@RequestBody CreateIngredientReq req){
        Ingredient saved = ingredientService.create(req.name, req.aliases);
        return new IngredientDto(saved.getId(), saved.getName(), saved.getAliases());
    }

    // ---- DTOs ----
    public static class IngredientDto {
        public Long id;
        public String name;
        public List<String> aliases;
        public IngredientDto() {}
        public IngredientDto(Long id, String name, List<String> aliases) {
            this.id = id; this.name = name; this.aliases = aliases;
        }
    }
    public static class CreateIngredientReq {
        public @NotBlank String name;
        public List<String> aliases = List.of();
    }
}