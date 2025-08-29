package com.example.recipe_sso.backend.dto;

public class SessionOut {
    private boolean ok;
    private String uid;
    private String email;

    public SessionOut(boolean ok, String uid, String email) {
        this.ok = ok;
        this.uid = uid;
        this.email = email;
    }

    public boolean isOk() { return ok; }
    public String getUid() { return uid; }
    public String getEmail() { return email; }
}