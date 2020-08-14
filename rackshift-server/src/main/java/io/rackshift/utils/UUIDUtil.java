

package io.rackshift.utils;

import java.util.UUID;

public class UUIDUtil {
    private UUIDUtil() {
    }

    public static String newUUID() {
        UUID uuid = UUID.randomUUID();
        return uuid.toString();
    }

    public static void main(String[] args) {

    }
}
