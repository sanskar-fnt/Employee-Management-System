package com.ems.util;

import java.security.SecureRandom;

/** Random temporary-password generator used at employee onboarding. */
public final class PasswordUtil {

    private static final SecureRandom RNG = new SecureRandom();
    private static final String LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz"; // omit O,o,I,l for legibility
    private static final String DIGITS  = "23456789";                                       // omit 0,1
    private static final String ALL     = LETTERS + DIGITS;

    private PasswordUtil() {}

    /** Generates a 12-char password guaranteed to contain ≥1 letter and ≥1 digit
     *  (so it satisfies the existing strength rules in UserService.validateNewUser). */
    public static String generateTempPassword() {
        char[] out = new char[12];
        out[0] = LETTERS.charAt(RNG.nextInt(LETTERS.length()));
        out[1] = DIGITS .charAt(RNG.nextInt(DIGITS .length()));
        for (int i = 2; i < out.length; i++) {
            out[i] = ALL.charAt(RNG.nextInt(ALL.length()));
        }
        // Shuffle so the guaranteed letter/digit are not always at index 0/1.
        for (int i = out.length - 1; i > 0; i--) {
            int j = RNG.nextInt(i + 1);
            char tmp = out[i]; out[i] = out[j]; out[j] = tmp;
        }
        return new String(out);
    }
}
