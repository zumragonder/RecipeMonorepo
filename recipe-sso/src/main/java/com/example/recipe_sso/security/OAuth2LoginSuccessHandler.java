/* package com.example.recipe_sso.security;

import java.io.IOException;
import java.time.Instant;
import java.util.Map;

import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import com.example.recipe_sso.user.User;
import com.example.recipe_sso.user.UserRepository;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class OAuth2LoginSuccessHandler implements AuthenticationSuccessHandler {

  private final UserRepository userRepository;

  public OAuth2LoginSuccessHandler(UserRepository userRepository) {
    this.userRepository = userRepository;
  }

  @Override
  public void onAuthenticationSuccess(HttpServletRequest request,
                                      HttpServletResponse response,
                                      Authentication authentication)
      throws IOException, ServletException {

    Map<String, Object> a =
        ((OAuth2AuthenticationToken) authentication).getPrincipal().getAttributes();

    String email   = (String) a.get("email");
    String name    = (String) a.getOrDefault("name", "");
    String picture = (String) a.getOrDefault("picture", "");
    String sub     = (String) a.get("sub");

    userRepository.findByEmail(email).map(u -> {
      u.setName(name);
      u.setPictureUrl(picture);
      u.setProviderId(sub);
      u.setLastLoginAt(Instant.now());
      return userRepository.save(u);
    }).orElseGet(() -> {
      User u = new User();
      u.setEmail(email);
      u.setName(name);
      u.setPictureUrl(picture);
      u.setProviderId(sub);
      u.setLastLoginAt(Instant.now());
      return userRepository.save(u);
    });

    response.sendRedirect("/dashboard");
  }
} */