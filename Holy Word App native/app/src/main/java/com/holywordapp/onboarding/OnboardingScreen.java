package com.holywordapp.onboarding;

public class OnboardingScreen {
    private int imageRes;
    private String title;
    private String description;
    private ScreenType screenType;

    public enum ScreenType {
        LANGUAGE_SELECTION,
        WELCOME,
        VIDEO_SHOWCASE,
        READY_TO_BEGIN
    }

    public OnboardingScreen(int imageRes, String title, String description, ScreenType screenType) {
        this.imageRes = imageRes;
        this.title = title;
        this.description = description;
        this.screenType = screenType;
    }

    public int getImageRes() {
        return imageRes;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public ScreenType getScreenType() {
        return screenType;
    }
}

