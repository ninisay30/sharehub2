package util;

import java.security.SecureRandom;

/**
 * Generates temporary passwords that are secure but still student-friendly to type.
 */
public final class TemporaryPasswordUtil {

    private static final char[] LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz".toCharArray();
    private static final char[] DIGITS = "23456789".toCharArray();
    private static final char[] SYMBOLS = "@#%+".toCharArray();
    private static final char[] ALL = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789@#%+".toCharArray();
    private static final SecureRandom RANDOM = new SecureRandom();

    private TemporaryPasswordUtil() {
    }

    public static String generate() {
        char[] password = new char[10];
        password[0] = LETTERS[RANDOM.nextInt(LETTERS.length)];
        password[1] = LETTERS[RANDOM.nextInt(LETTERS.length)];
        password[2] = DIGITS[RANDOM.nextInt(DIGITS.length)];
        password[3] = SYMBOLS[RANDOM.nextInt(SYMBOLS.length)];

        for (int i = 4; i < password.length; i++) {
            password[i] = ALL[RANDOM.nextInt(ALL.length)];
        }

        for (int i = password.length - 1; i > 0; i--) {
            int j = RANDOM.nextInt(i + 1);
            char temp = password[i];
            password[i] = password[j];
            password[j] = temp;
        }

        return new String(password);
    }
}
