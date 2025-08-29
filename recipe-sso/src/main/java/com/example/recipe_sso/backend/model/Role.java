package com.example.recipe_sso.backend.model;

public enum Role {
    USER,
    ADMIN;

    public String getRole() {
        return this.name();
    }

}