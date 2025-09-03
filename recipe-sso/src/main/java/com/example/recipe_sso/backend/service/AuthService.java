package com.example.recipe_sso.backend.service;

import java.time.Instant;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.example.recipe_sso.backend.model.User;
import com.example.recipe_sso.backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository users;

    public User loginOrRegisterGoogleUser(String email, String name, String pictureUrl, String providerId) {
        Optional<User> existing = users.findByEmail(email);

        if (existing.isPresent()) {
            User u = existing.get();
            u.setLastLoginAt(Instant.now());
            u.setName(name);
            u.setPictureUrl(pictureUrl);
            u.setProviderId(providerId);
            return users.save(u); // güncelle
        } else {
            User u = new User();
            u.setEmail(email);
            u.setName(name);
            u.setPictureUrl(pictureUrl);
            u.setProviderId(providerId);
            u.setLastLoginAt(Instant.now());
            return users.save(u); // yeni kayıt
        }
    }
}