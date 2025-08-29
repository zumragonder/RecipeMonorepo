/*package com.example.recipe_sso;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

import com.example.recipe_sso.security.OAuth2LoginSuccessHandler;

@Configuration
public class SecurityConfig {

  private final OAuth2LoginSuccessHandler successHandler;

  public SecurityConfig(OAuth2LoginSuccessHandler successHandler) {
    this.successHandler = successHandler;
  }

  @Bean
  SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
      .authorizeHttpRequests(a -> a
        .requestMatchers("/", "/css/**", "/js/**").permitAll()
        .anyRequest().authenticated()
      )
      .oauth2Login(o -> o.successHandler(successHandler))
      .logout(l -> l.logoutSuccessUrl("/").permitAll());

    return http.build();
  }
} */