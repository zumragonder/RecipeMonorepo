package com.example.recipe_sso.backend.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import com.example.recipe_sso.backend.model.Comment;

public interface CommentRepository extends JpaRepository<Comment, Long> {
    Page<Comment> findByRecipeId(Long recipeId, Pageable pageable);
}