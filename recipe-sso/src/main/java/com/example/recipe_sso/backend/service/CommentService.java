package com.example.recipe_sso.backend.service;

import com.example.recipe_sso.backend.model.Comment;
import com.example.recipe_sso.backend.model.Recipe;
import com.example.recipe_sso.backend.model.User;
import com.example.recipe_sso.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;

@Service
@RequiredArgsConstructor
public class CommentService {
    private final CommentRepository commentRepository;
    private final RecipeRepository recipeRepository;
    private final UserRepository userRepository;

    public Page<Comment> list(Long recipeId, Pageable pageable) {
        return commentRepository.findByRecipeId(recipeId, pageable);
    }

    @Transactional
    public Comment create(Long recipeId, Long userId, String text) {
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("recipe not found"));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));

        Comment c = new Comment();
        c.setRecipe(recipe);
        c.setUser(user);
        c.setText(text);
        c.setCreatedAt(new Date());
        return commentRepository.save(c);
    }
}