package com.example.recipe_sso.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.recipe_sso.backend.model.User;
import com.example.recipe_sso.backend.service.AuthService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/google")
    public ResponseEntity<User> googleLogin(@RequestBody GoogleLoginRequest request) {
        System.out.println("📩 Google login isteği geldi: " + request.getEmail());

        // DB'de user varsa günceller, yoksa yeni kayıt ekler
        User user = authService.loginOrRegisterGoogleUser(
                request.getEmail(),
                request.getName(),
                request.getPictureUrl(),
                request.getProviderId()
        );

        System.out.println("✅ Kaydedilen/Güncellenen kullanıcı: " + user.getEmail() + " (id=" + user.getId() + ")");

        return ResponseEntity.ok(user);
    }

    // Basit sağlık kontrolü endpointi
    @GetMapping("/x")
    public ResponseEntity<?> getSession() {
        System.out.println("⚡ Sağlık kontrolü endpointi çağrıldı");
        return ResponseEntity.ok("Auth endpoint is working!");
    }

    // Basit error DTO (şimdilik dursun)
    static class ErrorResponse {
        private final boolean ok = false;
        private final String error;
        public ErrorResponse(String error) { this.error = error; }
        public boolean isOk() { return ok; }
        public String getError() { return error; }
    }
}