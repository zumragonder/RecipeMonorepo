package com.example.recipe_sso.backend.service;

import java.util.Optional;

import org.springframework.stereotype.Service;

import com.example.recipe_sso.backend.model.User;
import com.example.recipe_sso.backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository users;

    public Optional<User> register(String email, String rawPassword, String displayName) {
        if (users.existsByEmail(email)) return Optional.empty();
        User u = new User();
        u.setEmail(email);
        u.setPasswordHash(rawPassword); // TODO: BCrypt ile hashle
        u.setDisplayName(displayName);
        return Optional.of(users.save(u));
    }

    public Optional<User> login(String email, String rawPassword) {
        return users.findByEmail(email)
                .filter(u -> u.getPasswordHash().equals(rawPassword)); // TODO: BCrypt match
    }
}