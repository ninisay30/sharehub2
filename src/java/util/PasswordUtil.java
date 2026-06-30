package util;

import org.mindrot.jbcrypt.BCrypt;

/**
 * Password hashing helper for ShareHub authentication.
 */
public final class PasswordUtil {

    private static final int BCRYPT_COST = 12;

    private PasswordUtil() {
        // Utility class.
    }

    public static String hashPassword(String plainPassword) {
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt(BCRYPT_COST));
    }

    public static boolean isBcryptHash(String storedPassword) {
        if (storedPassword == null) {
            return false;
        }
        return storedPassword.startsWith("$2a$")
                || storedPassword.startsWith("$2b$")
                || storedPassword.startsWith("$2y$");
    }

    public static boolean verifyPassword(String inputPassword, String storedPassword) {
        if (inputPassword == null || storedPassword == null) {
            return false;
        }

        if (isBcryptHash(storedPassword)) {
            try {
                return BCrypt.checkpw(inputPassword, storedPassword);
            } catch (IllegalArgumentException ex) {
                return false;
            }
        }

        // Legacy compatibility path: old accounts may still contain plaintext values.
        return storedPassword.equals(inputPassword);
    }
}

