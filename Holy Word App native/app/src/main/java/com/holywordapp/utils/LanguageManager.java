package com.holywordapp.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.Configuration;

import java.util.Locale;

public class LanguageManager {
    private static final String PREFS_NAME = "app_prefs";
    private static final String LANGUAGE_KEY = "selected_language";
    private static final String DEFAULT_LANGUAGE = "en";

    public static void setLanguage(Context context, String languageCode) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        prefs.edit().putString(LANGUAGE_KEY, languageCode).apply();
        applyLanguage(context, languageCode);
    }

    public static String getLanguage(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        return prefs.getString(LANGUAGE_KEY, DEFAULT_LANGUAGE);
    }

    public static void applyLanguage(Context context, String languageCode) {
        Locale locale;
        if (languageCode.equals("te")) {
            locale = new Locale("te");
        } else {
            locale = Locale.ENGLISH;
        }

        Locale.setDefault(locale);
        Configuration config = new Configuration(context.getResources().getConfiguration());
        config.setLocale(locale);
        context.getResources().updateConfiguration(config, context.getResources().getDisplayMetrics());
    }

    public static void applySavedLanguage(Context context) {
        String savedLanguage = getLanguage(context);
        applyLanguage(context, savedLanguage);
    }

    public static String getCurrentLanguage(Context context) {
        return getLanguage(context);
    }
}

