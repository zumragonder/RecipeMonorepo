package com.example.recipe_sso.backend.controller;

import java.time.Instant;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.recipe_sso.backend.model.User;
import com.example.recipe_sso.backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @PostMapping("/save")
    public ResponseEntity<User> saveUser(@RequestBody User incomingUser) {
        User user = userRepository.findByEmail(incomingUser.getEmail())
                .orElseGet(User::new);

        user.setEmail(incomingUser.getEmail());
        user.setName(incomingUser.getName());
        user.setPictureUrl(incomingUser.getPictureUrl());
        user.setProviderId(incomingUser.getProviderId());
        user.setLastLoginAt(Instant.now());

        User saved = userRepository.save(user);
        return ResponseEntity.ok(saved);
    }

    /** 👨‍🍳 Tüm şefleri listele */
    @GetMapping
    public List<UserDto> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(u -> new UserDto(u.getId(), u.getEmail(), u.getName()))
                .toList();
    }

    /** Şef DTO */
    public record UserDto(Long id, String email, String name) {}
}