package com.example.recipe_sso.backend.controller;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.recipe_sso.backend.dto.CreateRecipeRequest;
import com.example.recipe_sso.backend.model.Ingredient;
import com.example.recipe_sso.backend.model.Recipe;
import com.example.recipe_sso.backend.model.RecipeCategory;
import com.example.recipe_sso.backend.model.RecipeComment;
import com.example.recipe_sso.backend.model.RecipeLikeResponse;
import com.example.recipe_sso.backend.model.recipeingredient.RecipeIngredient;
import com.example.recipe_sso.backend.repository.RecipeCommentRepository;
import com.example.recipe_sso.backend.repository.RecipeLikeRepository;
import com.example.recipe_sso.backend.repository.UserRepository;
import com.example.recipe_sso.backend.service.RecipeService;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/recipes")
@RequiredArgsConstructor
public class RecipeController {

    private final RecipeService recipeService;
    private final RecipeLikeRepository likeRepo;
    private final RecipeCommentRepository commentRepo;
    private final UserRepository userRepo;

    /** 🔍 Tek tarif getir (DTO döner) */
    @GetMapping("/{id}")
    public ResponseEntity<RecipeDto> get(@PathVariable Long id) {
        return recipeService.get(id)
                .map(r -> ResponseEntity.ok(RecipeDto.fromEntity(r)))
                .orElse(ResponseEntity.notFound().build());
    }

    /** ➕ Yeni tarif oluştur (DTO döner) */
    @PostMapping
    public ResponseEntity<RecipeDto> create(@RequestBody CreateRecipeRequest req) {
        List<RecipeIngredient> items = new ArrayList<>();
        if (req.ingredients() != null) {
            for (var d : req.ingredients()) {
                Ingredient ing = new Ingredient();
                ing.setId(d.ingredientId());
                RecipeIngredient ri = new RecipeIngredient();
                ri.setIngredient(ing);
                ri.setAmount(d.amount());
                ri.setUnit(d.unit());
                items.add(ri);
            }
        }

        RecipeCategory category = null;
        if (req.category() != null) {
            category = RecipeCategory.valueOf(req.category().toUpperCase());
        }

        Recipe recipe;
        if (req.authorEmail() != null && !req.authorEmail().isBlank()) {
            recipe = recipeService.createRecipeByEmail(
                    req.title(),
                    req.description(),
                    req.authorEmail(),
                    items,
                    req.imageBase64(),
                    req.imagesBase64(),
                    category
            );
        } else {
            recipe = recipeService.createRecipe(
                    req.title(),
                    req.description(),
                    req.authorId(),
                    items,
                    req.imageBase64(),
                    req.imagesBase64(),
                    category
            );
        }

        return ResponseEntity.ok(RecipeDto.fromEntity(recipe));
    }

    /** 📊 Malzemelere göre önerilen tarifler */
    @GetMapping("/suggest")
    public Page<RecipeDto> suggest(@RequestParam List<Long> ingredientIds,
                                   @RequestParam(defaultValue = "0") int page,
                                   @RequestParam(defaultValue = "20") int size) {
        return recipeService.suggestByIngredients(ingredientIds, PageRequest.of(page, size))
                .map(RecipeDto::fromEntity);
    }

    /** 🔎 Arama */
    @GetMapping
    public Page<RecipeDto> search(@RequestParam(required = false) String name,
                                  @RequestParam(required = false) Integer minRating,
                                  @RequestParam(defaultValue = "0") int page,
                                  @RequestParam(defaultValue = "20") int size) {
        return recipeService.search(name, minRating, PageRequest.of(page, size))
                .map(RecipeDto::fromEntity);
    }

    /** 🍽️ Kategoriye göre tarifleri getir */
    @GetMapping("/category/{category}")
    public List<RecipeDto> getByCategory(@PathVariable RecipeCategory category) {
        return recipeService.getByCategory(category)
                .stream()
                .map(RecipeDto::fromEntity)
                .toList();
    }

    /** 👨‍🍳 Şefe göre tarifleri getir */
    @GetMapping("/author/{authorId}")
    public List<RecipeDto> getByAuthor(@PathVariable Long authorId) {
        return recipeService.getByAuthor(authorId)
                .stream()
                .map(RecipeDto::fromEntity)
                .toList();
    }

// ❤️ BEĞENİLER
@GetMapping("/{id}/likes/check")
public boolean checkLike(@PathVariable Long id, @RequestParam String email) {
    var user = userRepo.findByEmail(email).orElse(null);
    if (user == null) return false;
    return likeRepo.existsByRecipeIdAndUserId(id, user.getId());
}

@Transactional
@PostMapping("/{id}/likes/toggle")
public ResponseEntity<RecipeLikeResponse> toggleLike(
        @PathVariable Long id,
        @RequestParam String email) {

    var user = userRepo.findByEmail(email).orElse(null);
    if (user == null) {
        var res = new RecipeLikeResponse(false, 0, id, "Anonim kullanıcı beğeni atamaz");
        return ResponseEntity.status(403).body(res);
    }

    if (likeRepo.existsByRecipeIdAndUserId(id, user.getId())) {
        // 👍 Beğeniyi kaldır
        likeRepo.deleteByRecipeIdAndUserId(id, user.getId());
        var count = likeRepo.countByRecipeId(id);
        var res = new RecipeLikeResponse(false, count, id, "");
        return ResponseEntity.ok(res);

    } else {
        // ❤️ Yeni beğeni ekle
        var recipe = recipeService.get(id).orElseThrow();
        var like = new com.example.recipe_sso.backend.model.RecipeLike();
        like.setRecipe(recipe);
        like.setUser(user);
        likeRepo.save(like);

        var count = likeRepo.countByRecipeId(id);
        var res = new RecipeLikeResponse(true, count, id, "");  // 🔴 Burada true olacak
        return ResponseEntity.ok(res);
    }
}

// 💬 YORUMLAR
@PostMapping("/{id}/comments")
public ResponseEntity<?> addComment(@PathVariable Long id,
                                    @RequestParam String email,
                                    @RequestBody String text) {
    var user = userRepo.findByEmail(email).orElse(null);
    if (user == null) {
        return ResponseEntity.status(403).body("Anonim kullanıcı yorum atamaz");
    }

    var recipe = recipeService.get(id).orElseThrow();
    var c = new RecipeComment();
    c.setRecipe(recipe);
    c.setUser(user);
    c.setText(text);

    var saved = commentRepo.save(c);
    return ResponseEntity.ok(CommentDto.fromEntity(saved));
}

    // ---- DTO’lar ----
    public static class RecipeDto {
        public Long id;
        public String title;
        public String description;
        public String authorEmail;
        public String category;
        public String imageBase64;
        public List<String> imagesBase64;
        public List<IngredientLineDto> ingredients = new ArrayList<>();

        public static RecipeDto fromEntity(Recipe r) {
            RecipeDto dto = new RecipeDto();
            dto.id = r.getId();
            dto.title = r.getTitle();
            dto.description = r.getDescription();
            dto.authorEmail = r.getAuthor() != null ? r.getAuthor().getEmail() : null;
            dto.category = r.getCategory() != null ? r.getCategory().name() : null;
            dto.imageBase64 = r.getImageBase64();
            dto.imagesBase64 = r.getImagesBase64();

            if (r.getIngredients() != null) {
                for (RecipeIngredient ri : r.getIngredients()) {
                    dto.ingredients.add(IngredientLineDto.fromEntity(ri));
                }
            }
            return dto;
        }
    }

    public static class IngredientLineDto {
        public Long id;
        public String name;
        public String amount;
        public String unit;

        public static IngredientLineDto fromEntity(RecipeIngredient ri) {
            IngredientLineDto d = new IngredientLineDto();
            if (ri.getIngredient() != null) {
                d.id = ri.getIngredient().getId();
                d.name = ri.getIngredient().getName();
            }
            d.amount = ri.getAmount();
            d.unit = ri.getUnit();
            return d;
        }
    }

    public static class CommentDto {
        public Long id;
        public String text;
        public String userEmail;
        public java.time.Instant createdAt;

        public static CommentDto fromEntity(RecipeComment c) {
            CommentDto dto = new CommentDto();
            dto.id = c.getId();
            dto.text = c.getText();
            dto.userEmail = c.getUser() != null ? c.getUser().getEmail() : null;
            dto.createdAt = c.getCreatedAt();
            return dto;
        }
    }
}