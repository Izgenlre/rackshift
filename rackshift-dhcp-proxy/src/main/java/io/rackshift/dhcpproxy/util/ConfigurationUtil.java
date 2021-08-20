package io.rackshift.dhcpproxy.util;

import io.rackshift.dhcpproxy.config.MongoConfig;
import io.rackshift.dhcpproxy.constants.ConfigConstants;
import org.apache.commons.configuration.ConfigurationException;
import org.apache.commons.configuration.PropertiesConfiguration;

import java.util.Optional;

public class ConfigurationUtil {
    private static PropertiesConfiguration config;

    public static void init() {

        try {
            config = new PropertiesConfiguration(ConfigConstants.CONFIG_FILE);
            MongoConfig.config(config);
        } catch (ConfigurationException e) {
            ConsoleUtil.log("Cannot find " + ConfigConstants.CONFIG_FILE);
            throw new RuntimeException();
        }
    }

    public static String getConfig(String key, String defaultS) {
        return Optional.ofNullable(config.getString(key)).orElse(defaultS);
    }

}