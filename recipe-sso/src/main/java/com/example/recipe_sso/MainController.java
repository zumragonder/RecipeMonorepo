package com.example.recipe_sso;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class MainController {

    @GetMapping("/")
    public String home() { 
        return "home"; // templates/home.html
    }

    @GetMapping("/dashboard")
    //public String dashboard(Model model, OAuth2AuthenticationToken auth) {
    public String dashboard(Model model) {
        return "dashboard"; // templates/dashboard.html
    }
}