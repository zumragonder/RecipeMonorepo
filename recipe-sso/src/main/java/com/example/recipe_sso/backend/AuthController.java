package com.example.recipe_sso.backend;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.recipe_sso.backend.dto.SessionOut;
import com.example.recipe_sso.backend.dto.TokenIn;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;

@RestController
@RequestMapping("/api")
/* @CrossOrigin(
    origins = "*" // Flutter web origin
    //allowCredentials = "true"
) */
public class AuthController {

    @GetMapping("/x")
    public ResponseEntity<?> getSession() {
        return ResponseEntity.ok("Session endpoint is working!");
    }

    @PostMapping("/session")
    public ResponseEntity<?> createSession(@RequestBody TokenIn body) {
        try {
            if (body == null || body.getIdToken() == null || body.getIdToken().isBlank()) {
                return ResponseEntity.badRequest().body(
                    new ErrorResponse("missing_idToken")
                );
            }

            String idToken = body.getIdToken();

            // 🔐 Firebase idToken doğrulama
            FirebaseToken decoded = FirebaseAuth.getInstance().verifyIdToken(idToken);

            String uid = decoded.getUid();
            String email = decoded.getEmail(); // google.com için dolu, anonymous için null olabilir

            // (İsteğe bağlı) log
           // System.out.println("✅ Verified user: uid=" + uid + ", email=" + email +
              //                 ", provider=" + (decoded. getFirebase() != null ? decoded.getFirebase().getSignInProvider() : "n/a"));

            return ResponseEntity.ok(new SessionOut(true, uid, email));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(401).body(new ErrorResponse("invalid_token"));
        }
    }

    // Basit error DTO
    static class ErrorResponse {
        private final boolean ok = false;
        private final String error;
        public ErrorResponse(String error) { this.error = error; }
        public boolean isOk() { return ok; }
        public String getError() { return error; }
    }
}