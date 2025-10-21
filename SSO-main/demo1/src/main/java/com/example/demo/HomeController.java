package com.example.demo;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @GetMapping("/secure")
    public String secure(@AuthenticationPrincipal OidcUser oidcUser, Model model) {
        if (oidcUser != null) {
            model.addAttribute("name", oidcUser.getFullName());
            model.addAttribute("email", oidcUser.getEmail());
            model.addAttribute("claims", oidcUser.getClaims());
            model.addAttribute("idToken", oidcUser.getIdToken().getTokenValue());
        }
        return "secure";
    }

    @GetMapping("/logout-remote")
    public String logoutRemote(@AuthenticationPrincipal OidcUser oidcUser) {
        String idToken = oidcUser != null ? oidcUser.getIdToken().getTokenValue() : "";
        String redirect = "http://localhost:8081/";
        String logoutUrl = "http://localhost:8080/realms/demo-realm/protocol/openid-connect/logout"
                + "?redirect_uri=" + redirect
                + "&id_token_hint=" + idToken;
        return "redirect:" + logoutUrl;
    }
}
