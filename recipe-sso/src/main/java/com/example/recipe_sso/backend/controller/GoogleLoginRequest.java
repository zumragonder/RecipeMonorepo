package com.example.recipe_sso.backend.controller;

import lombok.Data;

@Data
public class GoogleLoginRequest {
    private String email;
    private String name;
    private String pictureUrl;
    private String providerId;
}