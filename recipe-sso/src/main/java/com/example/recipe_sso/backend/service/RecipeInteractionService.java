package com.example.recipe_sso.backend.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.recipe_sso.backend.model.Recipe;
import com.example.recipe_sso.backend.model.RecipeComment;
import com.example.recipe_sso.backend.model.RecipeLike;
import com.example.recipe_sso.backend.model.User;
import com.example.recipe_sso.backend.repository.RecipeCommentRepository;
import com.example.recipe_sso.backend.repository.RecipeLikeRepository;
import com.example.recipe_sso.backend.repository.RecipeRepository;
import com.example.recipe_sso.backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class RecipeInteractionService {

    private final RecipeLikeRepository likeRepository;
    private final RecipeCommentRepository commentRepository;
    private final RecipeRepository recipeRepository;
    private final UserRepository userRepository;

    /** ❤️ Tarif beğen */
    @Transactional
    public void likeRecipe(Long recipeId, Long userId) {
        if (likeRepository.existsByRecipeIdAndUserId(recipeId, userId)) {
            return; // zaten beğenmiş
        }
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("recipe not found"));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));

        RecipeLike like = new RecipeLike();
        like.setRecipe(recipe);
        like.setUser(user);
        likeRepository.save(like);
    }

    /** 💔 Beğeni kaldır */
    @Transactional
    public void unlikeRecipe(Long recipeId, Long userId) {
        likeRepository.deleteByRecipeIdAndUserId(recipeId, userId);
    }

    /** 📊 Beğeni sayısı */
    public long countLikes(Long recipeId) {
        return likeRepository.countByRecipeId(recipeId);
    }

    /** 💬 Yorum ekle */
    @Transactional
    public RecipeComment addComment(Long recipeId, Long userId, String text) {
        Recipe recipe = recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("recipe not found"));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found"));

        RecipeComment comment = new RecipeComment();
        comment.setRecipe(recipe);
        comment.setUser(user);
        comment.setText(text);
        return commentRepository.save(comment);
    }

    /** 📖 Tarif yorumlarını getir */
    public List<RecipeComment> getComments(Long recipeId) {
        return commentRepository.findByRecipeIdOrderByCreatedAtDesc(recipeId);
    }
}