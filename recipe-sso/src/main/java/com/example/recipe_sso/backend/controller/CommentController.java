package com.example.recipe_sso.backend.controller;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.recipe_sso.backend.model.Comment;
import com.example.recipe_sso.backend.service.CommentService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/recipes/{recipeId}/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    @GetMapping
    public Page<Comment> list(@PathVariable Long recipeId,
                              @RequestParam(defaultValue = "0") int page,
                              @RequestParam(defaultValue = "20") int size) {
        return commentService.list(recipeId, PageRequest.of(page, size));
    }

    @PostMapping
    public Comment create(@PathVariable Long recipeId,
                          @RequestBody CreateCommentReq req) {
        return commentService.create(recipeId, req.userId, req.text);
    }

    public static class CreateCommentReq {
        public Long userId;   // güvenlik ekleyene kadar böyle
        public String text;
    }
}