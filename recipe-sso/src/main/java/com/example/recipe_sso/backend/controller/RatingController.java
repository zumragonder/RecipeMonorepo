package com.example.recipe_sso.backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.recipe_sso.backend.model.rating.Rating;
import com.example.recipe_sso.backend.service.RatingService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/recipes/{recipeId}/ratings")
@RequiredArgsConstructor
public class RatingController {

    private final RatingService ratingService;

    @PostMapping
    public ResponseEntity<Rating> rate(@PathVariable Long recipeId,
                                       @RequestBody RateReq req) {
        try {
            Rating r = ratingService.rate(recipeId, req.userId, req.score);
            return ResponseEntity.ok(r);
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }
    }

    public static class RateReq {
        public Long userId; // güvenlik ekleyene kadar böyle
        public int score;   // 1..5
    }
}