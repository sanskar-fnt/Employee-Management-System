package com.ems.util;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.util.UUID;

public final class CsrfUtil {

    private static final String COOKIE_NAME = "XSRF-TOKEN";

    private CsrfUtil() {
    }

    public static String ensureToken(HttpSession session) {
        if (session == null) {
            return "";
        }
        String token = (String) session.getAttribute("csrfToken");
        if (token == null || token.trim().isEmpty()) {
            token = UUID.randomUUID().toString();
            session.setAttribute("csrfToken", token);
        }
        return token;
    }

    public static void ensureCookie(HttpServletRequest request, HttpServletResponse response) {
        if (response == null) return;
        HttpSession session = request == null ? null : request.getSession(false);
        String token = null;
        if (session != null) token = (String) session.getAttribute("csrfToken");
        if (token == null || token.trim().isEmpty()) {
            // create a new token and attach to session
            if (session == null) session = request.getSession(true);
            token = ensureToken(session);
        }
        Cookie cookie = new Cookie(COOKIE_NAME, token);
        cookie.setPath(request == null ? "/" : request.getContextPath().isEmpty() ? "/" : request.getContextPath());
        // Not HttpOnly so front-end JS (if needed) can read it for double-submit validation
        cookie.setHttpOnly(false);
        response.addCookie(cookie);
    }

    public static boolean isValid(HttpServletRequest request) {
        if (request == null) {
            return false;
        }
        HttpSession session = request.getSession(false);
        String sessionToken = session == null ? null : (String) session.getAttribute("csrfToken");
        String param = request.getParameter("csrfToken");
        if (sessionToken != null && sessionToken.equals(param)) {
            return true;
        }
        // fallback: check cookie (double-submit)
        String cookieToken = getCookieValue(request, COOKIE_NAME);
        if (cookieToken != null && cookieToken.equals(param)) {
            return true;
        }
        return false;
    }

    private static String getCookieValue(HttpServletRequest request, String name) {
        if (request == null || name == null) return null;
        Cookie[] cookies = request.getCookies();
        if (cookies == null) return null;
        for (Cookie c : cookies) {
            if (name.equals(c.getName())) {
                return c.getValue();
            }
        }
        return null;
    }
}