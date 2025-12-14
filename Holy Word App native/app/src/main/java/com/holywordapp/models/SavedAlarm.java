package com.holywordapp.models;

public class SavedAlarm {
    private int id;
    private String name;
    private String time;
    private String days; // 7-bit string: Sun, Mon, Tue, Wed, Thu, Fri, Sat (1=enabled, 0=disabled)
    private boolean isActive;
    
    public SavedAlarm(int id, String name, String time, String days, boolean isActive) {
        this.id = id;
        this.name = name;
        this.time = time;
        this.days = days;
        this.isActive = isActive;
    }
    
    // Getters and Setters
    public int getId() {
        return id;
    }
    
    public void setId(int id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getTime() {
        return time;
    }
    
    public void setTime(String time) {
        this.time = time;
    }
    
    public String getDays() {
        return days;
    }
    
    public void setDays(String days) {
        this.days = days;
    }
    
    public boolean isActive() {
        return isActive;
    }
    
    public void setActive(boolean active) {
        isActive = active;
    }
    
    // Helper methods
    public String getDaysText() {
        String[] dayNames = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
        StringBuilder result = new StringBuilder();
        
        for (int i = 0; i < 7; i++) {
            if (days.charAt(i) == '1') {
                if (result.length() > 0) {
                    result.append(", ");
                }
                result.append(dayNames[i]);
            }
        }
        
        return result.length() > 0 ? result.toString() : "No days selected";
    }
    
    public boolean isDayEnabled(int dayIndex) {
        return days.charAt(dayIndex) == '1';
    }
    
    public void setDayEnabled(int dayIndex, boolean enabled) {
        char[] daysArray = days.toCharArray();
        daysArray[dayIndex] = enabled ? '1' : '0';
        days = new String(daysArray);
    }
}

