package com.example.recipe_sso.backend;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;

@Configuration
public class FirebaseConfig {

    public FirebaseConfig() throws IOException {
        // 1) Tercih edilen yöntem: GOOGLE_APPLICATION_CREDENTIALS env değişkeni
        // export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
        // FirebaseApp.initializeApp();  // Eğer env set ise bu tek satır yeterli olur.

        // 2) Ya da dosya yolunu direkt ver:
        String path = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
        if (path != null && !path.isEmpty()) {
            try (FileInputStream serviceAccount = new FileInputStream(path)) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();
                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp.initializeApp(options);
                }
            }
        } else {
           ClassPathResource resource = new ClassPathResource("serviceAccount.json");
        try (InputStream is = resource.getInputStream()) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(is))
                    .build();
            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
            }
        }
        }
    }
}