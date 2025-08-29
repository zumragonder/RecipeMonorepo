package com.example.recipe_sso.backend.service;

import org.springframework.stereotype.Service;

import com.example.recipe_sso.backend.repository.CommentRepository;
import com.example.recipe_sso.backend.repository.RecipeRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final RecipeRepository recipeRepository;
    private final CommentRepository commentRepository;

    public boolean deleteRecipe(Long id) {
        if (recipeRepository.existsById(id)) {
            recipeRepository.deleteById(id);
            return true;
        }
        return false;
    }

    public boolean deleteComment(Long id) {
        if (commentRepository.existsById(id)) {
            commentRepository.deleteById(id);
            return true;
        }
        return false;
    }
}