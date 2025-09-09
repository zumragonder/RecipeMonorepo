package com.example.recipe_sso.backend.controller;

import java.util.List;
import java.util.Locale;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.recipe_sso.backend.model.Ingredient;
import com.example.recipe_sso.backend.model.IngredientCategory;
import com.example.recipe_sso.backend.service.IngredientService;

import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/ingredients")
@RequiredArgsConstructor
public class IngredientController {

    private final IngredientService ingredientService;

    /** Autocomplete (içeren, A→Z) */
    @GetMapping("/autocomplete")
    public List<IngredientDto> autocomplete(
            @RequestParam("q") @NotBlank String q,
            @RequestParam(defaultValue = "10") int limit) {
        return ingredientService.autocomplete(q, limit).stream()
                .map(IngredientDto::from)
                .toList();
    }

    /** Tüm havuz (opsiyonel kategori filtresi, A→Z) */
    @GetMapping("/all")
    public List<IngredientDto> all(@RequestParam(name = "category", required = false) String category) {
        Optional<IngredientCategory> cat = parseCategory(category);
        List<Ingredient> items = cat.isPresent()
                ? ingredientService.findAllByCategory(cat.get())
                : ingredientService.findAll();
        return items.stream().map(IngredientDto::from).toList();
    }

    /** Yeni malzeme ekle (case-insensitive, kategori destekli) */
    @PostMapping
    public ResponseEntity<?> create(@RequestBody CreateIngredientReq req) {
        String name = req.name == null ? "" : req.name.trim();
        if (name.isBlank()) {
            return ResponseEntity.badRequest().body(new ErrorDto("name is blank"));
        }

        // Aynı isim varsa 409 + mevcut kaydı döndür
        Optional<Ingredient> existingOpt = ingredientService.findByNameIgnoreCase(name);
        if (existingOpt.isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(new InfoDto("already_exists", IngredientDto.from(existingOpt.get())));
        }

        // Kategori güvenli parse (gelmezse OTHER)
        IngredientCategory category = parseCategory(req.category).orElse(IngredientCategory.OTHER);

        Ingredient saved = ingredientService.create(name, req.aliases, category);
        return ResponseEntity.ok(IngredientDto.from(saved));
    }

    // ---------- Helpers & DTOs ----------

    static Optional<IngredientCategory> parseCategory(String raw) {
        if (raw == null || raw.isBlank()) return Optional.empty();
        try {
            return Optional.of(IngredientCategory.valueOf(raw.trim().toUpperCase(Locale.ROOT)));
        } catch (IllegalArgumentException ex) {
            return Optional.empty();
        }
    }

    public static class IngredientDto {
        public Long id;
        public String name;
        public List<String> aliases;
        public String category;

        public static IngredientDto from(Ingredient i) {
            IngredientDto d = new IngredientDto();
            d.id = i.getId();
            d.name = i.getName();
            d.aliases = i.getAliases();
            d.category = i.getCategory().name();
            return d;
        }
    }

    public static class CreateIngredientReq {
        public @NotBlank String name;
        public List<String> aliases = List.of();
        public String category; // MEAT/SEAFOOD/DAIRY/.../OTHER (opsiyonel)
    }

    public static class ErrorDto {
        public final boolean ok = false;
        public final String error;
        public ErrorDto(String error) { this.error = error; }
    }

    public static class InfoDto {
        public final String code;
        public final IngredientDto data;
        public InfoDto(String code, IngredientDto data) { this.code = code; this.data = data; }
    }
}