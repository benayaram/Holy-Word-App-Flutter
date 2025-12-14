package com.holywordapp;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.holywordapp.adapters.SavedAlarmsAdapter;
import com.holywordapp.models.SavedAlarm;

import java.util.ArrayList;
import java.util.List;

public class SavedAlarmsActivity extends AppCompatActivity {
    
    private RecyclerView alarmsRecyclerView;
    private SavedAlarmsAdapter alarmsAdapter;
    private List<SavedAlarm> savedAlarms;
    private FloatingActionButton addAlarmFab;
    private MaterialButton backButton;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_saved_alarms);
        
        initViews();
        loadSavedAlarms();
        setupRecyclerView();
    }
    
    private void initViews() {
        alarmsRecyclerView = findViewById(R.id.alarms_recycler_view);
        addAlarmFab = findViewById(R.id.add_alarm_fab);
        backButton = findViewById(R.id.back_button);
        
        backButton.setOnClickListener(v -> finish());
        addAlarmFab.setOnClickListener(v -> {
            // Open the existing prayer reminder dialog
            openPrayerReminderDialog();
        });
    }
    
    private void loadSavedAlarms() {
        savedAlarms = new ArrayList<>();
        
        try {
            SharedPreferences prefs = getSharedPreferences("saved_alarms", MODE_PRIVATE);
            int alarmCount = prefs.getInt("alarm_count", 0);
            
            for (int i = 0; i < alarmCount; i++) {
                String name = prefs.getString("alarm_" + i + "_name", null);
                String time = prefs.getString("alarm_" + i + "_time", null);
                String days = prefs.getString("alarm_" + i + "_days", "1111111"); // Default: all days
                boolean isActive = prefs.getBoolean("alarm_" + i + "_active", true);
                
                if (name != null && time != null) {
                    SavedAlarm alarm = new SavedAlarm(i, name, time, days, isActive);
                    savedAlarms.add(alarm);
                }
            }
            
            Log.d("SavedAlarms", "Loaded " + savedAlarms.size() + " saved alarms");
            
        } catch (Exception e) {
            Log.e("SavedAlarms", "Error loading saved alarms", e);
        }
    }
    
    private void setupRecyclerView() {
        alarmsAdapter = new SavedAlarmsAdapter(savedAlarms, new SavedAlarmsAdapter.OnAlarmActionListener() {
            @Override
            public void onEditAlarm(SavedAlarm alarm) {
                // Open the existing prayer reminder dialog with pre-filled data
                openEditAlarmDialog(alarm);
            }
            
            @Override
            public void onDeleteAlarm(SavedAlarm alarm) {
                deleteAlarm(alarm);
            }
            
            @Override
            public void onToggleAlarm(SavedAlarm alarm) {
                toggleAlarm(alarm);
            }
        });
        
        alarmsRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        alarmsRecyclerView.setAdapter(alarmsAdapter);
    }
    
    private void deleteAlarm(SavedAlarm alarm) {
        try {
            // Cancel the alarm
            cancelAlarm(alarm.getId());
            
            // Remove from SharedPreferences
            SharedPreferences prefs = getSharedPreferences("saved_alarms", MODE_PRIVATE);
            SharedPreferences.Editor editor = prefs.edit();
            
            int alarmCount = prefs.getInt("alarm_count", 0);
            
            // Remove the alarm data
            editor.remove("alarm_" + alarm.getId() + "_name");
            editor.remove("alarm_" + alarm.getId() + "_time");
            editor.remove("alarm_" + alarm.getId() + "_days");
            editor.remove("alarm_" + alarm.getId() + "_active");
            
            // Shift remaining alarms down
            for (int i = alarm.getId() + 1; i < alarmCount; i++) {
                String name = prefs.getString("alarm_" + i + "_name", null);
                String time = prefs.getString("alarm_" + i + "_time", null);
                String days = prefs.getString("alarm_" + i + "_days", "1111111");
                boolean isActive = prefs.getBoolean("alarm_" + i + "_active", true);
                
                if (name != null && time != null) {
                    editor.putString("alarm_" + (i - 1) + "_name", name);
                    editor.putString("alarm_" + (i - 1) + "_time", time);
                    editor.putString("alarm_" + (i - 1) + "_days", days);
                    editor.putBoolean("alarm_" + (i - 1) + "_active", isActive);
                    
                    editor.remove("alarm_" + i + "_name");
                    editor.remove("alarm_" + i + "_time");
                    editor.remove("alarm_" + i + "_days");
                    editor.remove("alarm_" + i + "_active");
                }
            }
            
            editor.putInt("alarm_count", alarmCount - 1);
            editor.apply();
            
            // Remove from list and update adapter
            savedAlarms.remove(alarm);
            alarmsAdapter.notifyDataSetChanged();
            
            Toast.makeText(this, "Alarm deleted successfully", Toast.LENGTH_SHORT).show();
            
            Log.d("SavedAlarms", "Alarm deleted: " + alarm.getName());
            
        } catch (Exception e) {
            Log.e("SavedAlarms", "Error deleting alarm", e);
            Toast.makeText(this, "Error deleting alarm", Toast.LENGTH_SHORT).show();
        }
    }
    
    private void toggleAlarm(SavedAlarm alarm) {
        try {
            alarm.setActive(!alarm.isActive());
            
            if (alarm.isActive()) {
                // Set the alarm
                setAlarm(alarm);
            } else {
                // Cancel the alarm
                cancelAlarm(alarm.getId());
            }
            
            // Update SharedPreferences
            SharedPreferences prefs = getSharedPreferences("saved_alarms", MODE_PRIVATE);
            SharedPreferences.Editor editor = prefs.edit();
            editor.putBoolean("alarm_" + alarm.getId() + "_active", alarm.isActive());
            editor.apply();
            
            // Update adapter
            alarmsAdapter.notifyDataSetChanged();
            
            String status = alarm.isActive() ? "enabled" : "disabled";
            Toast.makeText(this, "Alarm " + status, Toast.LENGTH_SHORT).show();
            
            Log.d("SavedAlarms", "Alarm toggled: " + alarm.getName() + " - " + status);
            
        } catch (Exception e) {
            Log.e("SavedAlarms", "Error toggling alarm", e);
            Toast.makeText(this, "Error toggling alarm", Toast.LENGTH_SHORT).show();
        }
    }
    
    private void setAlarm(SavedAlarm alarm) {
        try {
            AlarmManager alarmManager = (AlarmManager) getSystemService(Context.ALARM_SERVICE);
            
            // Parse time
            String[] timeParts = alarm.getTime().split(":");
            int hour = Integer.parseInt(timeParts[0]);
            int minute = Integer.parseInt(timeParts[1]);
            
            // Parse days (7-bit string: Sun, Mon, Tue, Wed, Thu, Fri, Sat)
            String days = alarm.getDays();
            
            // Set alarm for each selected day
            for (int day = 0; day < 7; day++) {
                if (days.charAt(day) == '1') {
                    java.util.Calendar calendar = java.util.Calendar.getInstance();
                    calendar.set(java.util.Calendar.HOUR_OF_DAY, hour);
                    calendar.set(java.util.Calendar.MINUTE, minute);
                    calendar.set(java.util.Calendar.SECOND, 0);
                    calendar.set(java.util.Calendar.MILLISECOND, 0);
                    
                    // Set to next occurrence of this day
                    int currentDay = calendar.get(java.util.Calendar.DAY_OF_WEEK);
                    int targetDay = (day == 0) ? java.util.Calendar.SUNDAY : day + 1;
                    
                    int daysUntilTarget = (targetDay - currentDay + 7) % 7;
                    if (daysUntilTarget == 0) {
                        // If it's today, check if time has passed
                        if (calendar.getTimeInMillis() <= System.currentTimeMillis()) {
                            daysUntilTarget = 7; // Next week
                        }
                    }
                    
                    calendar.add(java.util.Calendar.DAY_OF_MONTH, daysUntilTarget);
                    
                    // Create intent
                    Intent intent = new Intent(this, PrayerReminderReceiver.class);
                    intent.putExtra("reminder_name", alarm.getName());
                    intent.putExtra("reminder_time", alarm.getTime());
                    intent.putExtra("alarm_id", alarm.getId());
                    
                    PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 
                        alarm.getId() * 10 + day, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                    
                    // Set repeating alarm for this day
                    alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(),
                        AlarmManager.INTERVAL_DAY * 7, pendingIntent);
                }
            }
            
            Log.d("SavedAlarms", "Alarm set: " + alarm.getName());
            
        } catch (Exception e) {
            Log.e("SavedAlarms", "Error setting alarm", e);
        }
    }
    
    private void cancelAlarm(int alarmId) {
        try {
            AlarmManager alarmManager = (AlarmManager) getSystemService(Context.ALARM_SERVICE);
            
            // Cancel all alarms for this alarm ID (7 days)
            for (int day = 0; day < 7; day++) {
                Intent intent = new Intent(this, PrayerReminderReceiver.class);
                PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 
                    alarmId * 10 + day, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                
                alarmManager.cancel(pendingIntent);
            }
            
            Log.d("SavedAlarms", "Alarm cancelled: " + alarmId);
            
        } catch (Exception e) {
            Log.e("SavedAlarms", "Error cancelling alarm", e);
        }
    }
    
    // Open Prayer Reminder Dialog
    private void openPrayerReminderDialog() {
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(this);
        android.view.View dialogView = android.view.LayoutInflater.from(this).inflate(R.layout.prayer_reminder_setup_enhanced, null);
        builder.setView(dialogView);
        builder.setCancelable(true);
        
        android.app.AlertDialog dialog = builder.create();
        dialog.show();
        
        initPrayerReminderViews(dialogView, dialog);
    }
    
    private void initPrayerReminderViews(android.view.View dialogView, android.app.AlertDialog dialog) {
        android.widget.EditText reminderNameInput = dialogView.findViewById(R.id.reminder_name_input);
        com.google.android.material.button.MaterialButton timePickerButton = dialogView.findViewById(R.id.time_picker_button);
        android.widget.TextView selectedTimeDisplay = dialogView.findViewById(R.id.selected_time_display);
        com.google.android.material.button.MaterialButton saveReminderButton = dialogView.findViewById(R.id.save_reminder_button);
        com.google.android.material.button.MaterialButton cancelReminderButton = dialogView.findViewById(R.id.cancel_reminder_button);
        android.widget.ImageButton closeReminderButton = dialogView.findViewById(R.id.close_reminder_button);
        
        // Day selection chips
        com.google.android.material.chip.Chip sundayChip = dialogView.findViewById(R.id.sunday_chip);
        com.google.android.material.chip.Chip mondayChip = dialogView.findViewById(R.id.monday_chip);
        com.google.android.material.chip.Chip tuesdayChip = dialogView.findViewById(R.id.tuesday_chip);
        com.google.android.material.chip.Chip wednesdayChip = dialogView.findViewById(R.id.wednesday_chip);
        com.google.android.material.chip.Chip thursdayChip = dialogView.findViewById(R.id.thursday_chip);
        com.google.android.material.chip.Chip fridayChip = dialogView.findViewById(R.id.friday_chip);
        com.google.android.material.chip.Chip saturdayChip = dialogView.findViewById(R.id.saturday_chip);
        
        // Quick selection buttons
        com.google.android.material.button.MaterialButton weekdaysButton = dialogView.findViewById(R.id.weekdays_button);
        com.google.android.material.button.MaterialButton weekendsButton = dialogView.findViewById(R.id.weekends_button);
        com.google.android.material.button.MaterialButton allDaysButton = dialogView.findViewById(R.id.all_days_button);
        
        // Store chips in array for easy access
        com.google.android.material.chip.Chip[] dayChips = {
            sundayChip, mondayChip, tuesdayChip, wednesdayChip, 
            thursdayChip, fridayChip, saturdayChip
        };
        
        // Set current time as default
        java.util.Calendar calendar = java.util.Calendar.getInstance();
        selectedTimeDisplay.setText(String.format(java.util.Locale.getDefault(), "%02d:%02d", 
            calendar.get(java.util.Calendar.HOUR_OF_DAY), calendar.get(java.util.Calendar.MINUTE)));
        
        // Set default days (all days selected)
        for (com.google.android.material.chip.Chip chip : dayChips) {
            chip.setChecked(true);
        }
        
        // Time picker button click
        timePickerButton.setOnClickListener(v -> {
            android.app.TimePickerDialog timePickerDialog = new android.app.TimePickerDialog(this,
                (view, hourOfDay, minute) -> {
                    selectedTimeDisplay.setText(String.format(java.util.Locale.getDefault(), "%02d:%02d", hourOfDay, minute));
                },
                calendar.get(java.util.Calendar.HOUR_OF_DAY),
                calendar.get(java.util.Calendar.MINUTE),
                true);
            timePickerDialog.show();
        });
        
        // Quick selection buttons
        weekdaysButton.setOnClickListener(v -> {
            // Select Monday to Friday
            for (int i = 1; i <= 5; i++) {
                dayChips[i].setChecked(true);
            }
            dayChips[0].setChecked(false); // Sunday
            dayChips[6].setChecked(false); // Saturday
        });
        
        weekendsButton.setOnClickListener(v -> {
            // Select Saturday and Sunday
            dayChips[0].setChecked(true);  // Sunday
            dayChips[6].setChecked(true);   // Saturday
            for (int i = 1; i <= 5; i++) {
                dayChips[i].setChecked(false); // Monday to Friday
            }
        });
        
        allDaysButton.setOnClickListener(v -> {
            // Select all days
            for (com.google.android.material.chip.Chip chip : dayChips) {
                chip.setChecked(true);
            }
        });
        
        // Save button
        saveReminderButton.setOnClickListener(v -> {
            String reminderName = reminderNameInput.getText().toString().trim();
            String timeText = selectedTimeDisplay.getText().toString();
            
            if (android.text.TextUtils.isEmpty(reminderName)) {
                Toast.makeText(this, "Please enter alarm name", Toast.LENGTH_SHORT).show();
                return;
            }
            
            if (android.text.TextUtils.isEmpty(timeText)) {
                Toast.makeText(this, "Please select a time", Toast.LENGTH_SHORT).show();
                return;
            }
            
            // Get selected days
            StringBuilder daysBuilder = new StringBuilder();
            for (com.google.android.material.chip.Chip chip : dayChips) {
                daysBuilder.append(chip.isChecked() ? "1" : "0");
            }
            String selectedDays = daysBuilder.toString();
            
            // Check if at least one day is selected
            if (!selectedDays.contains("1")) {
                Toast.makeText(this, "Please select at least one day", Toast.LENGTH_SHORT).show();
                return;
            }
            
            saveAlarmToSavedAlarms(reminderName, timeText, selectedDays);
            dialog.dismiss();
        });
        
        // Cancel button
        cancelReminderButton.setOnClickListener(v -> dialog.dismiss());
        
        // Close button
        closeReminderButton.setOnClickListener(v -> dialog.dismiss());
    }
    
    private void saveAlarmToSavedAlarms(String reminderName, String timeText, String selectedDays) {
        try {
            SharedPreferences prefs = getSharedPreferences("saved_alarms", MODE_PRIVATE);
            int alarmCount = prefs.getInt("alarm_count", 0);
            
            // Save new alarm
            SharedPreferences.Editor editor = prefs.edit();
            editor.putString("alarm_" + alarmCount + "_name", reminderName);
            editor.putString("alarm_" + alarmCount + "_time", timeText);
            editor.putString("alarm_" + alarmCount + "_days", selectedDays);
            editor.putBoolean("alarm_" + alarmCount + "_active", true);
            editor.putInt("alarm_count", alarmCount + 1);
            editor.apply();
            
            // Set the alarm
            setAlarmForSavedAlarm(alarmCount, reminderName, timeText, selectedDays);
            
            // Refresh the list
            loadSavedAlarms();
            setupRecyclerView();
            
            Toast.makeText(this, "Alarm saved successfully!", Toast.LENGTH_SHORT).show();
            
            Log.d("SavedAlarms", "Alarm saved: " + reminderName + " at " + timeText + " for days: " + selectedDays);
            
        } catch (Exception e) {
            Log.e("SavedAlarms", "Error saving alarm", e);
            Toast.makeText(this, "Error saving alarm", Toast.LENGTH_SHORT).show();
        }
    }
    
    private void setAlarmForSavedAlarm(int alarmId, String reminderName, String timeText, String days) {
        try {
            AlarmManager alarmManager = (AlarmManager) getSystemService(Context.ALARM_SERVICE);
            
            // Parse time
            String[] timeParts = timeText.split(":");
            int hour = Integer.parseInt(timeParts[0]);
            int minute = Integer.parseInt(timeParts[1]);
            
            // Set alarm for each selected day
            for (int day = 0; day < 7; day++) {
                if (days.charAt(day) == '1') {
                    java.util.Calendar calendar = java.util.Calendar.getInstance();
                    calendar.set(java.util.Calendar.HOUR_OF_DAY, hour);
                    calendar.set(java.util.Calendar.MINUTE, minute);
                    calendar.set(java.util.Calendar.SECOND, 0);
                    calendar.set(java.util.Calendar.MILLISECOND, 0);
                    
                    // Set to next occurrence of this day
                    int currentDay = calendar.get(java.util.Calendar.DAY_OF_WEEK);
                    int targetDay = (day == 0) ? java.util.Calendar.SUNDAY : day + 1;
                    
                    int daysUntilTarget = (targetDay - currentDay + 7) % 7;
                    if (daysUntilTarget == 0) {
                        // If it's today, check if time has passed
                        if (calendar.getTimeInMillis() <= System.currentTimeMillis()) {
                            daysUntilTarget = 7; // Next week
                        }
                    }
                    
                    calendar.add(java.util.Calendar.DAY_OF_MONTH, daysUntilTarget);
                    
                    // Create intent
                    Intent intent = new Intent(this, PrayerReminderReceiver.class);
                    intent.putExtra("reminder_name", reminderName);
                    intent.putExtra("reminder_time", timeText);
                    intent.putExtra("alarm_id", alarmId);
                    
                    PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 
                        alarmId * 10 + day, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
                    
                    // Set exact alarm for this day with repeating
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(), pendingIntent);
                        // Set repeating alarm for weekly
                        alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(),
                            AlarmManager.INTERVAL_DAY * 7, pendingIntent);
                    } else {
                        alarmManager.setExact(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(), pendingIntent);
                        alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(),
                            AlarmManager.INTERVAL_DAY * 7, pendingIntent);
                    }
                }
            }
            
            Log.d("SavedAlarms", "Alarm set: " + reminderName);
            
        } catch (Exception e) {
            Log.e("SavedAlarms", "Error setting alarm", e);
        }
    }
    
    // Open Edit Alarm Dialog
    private void openEditAlarmDialog(SavedAlarm alarm) {
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(this);
        android.view.View dialogView = android.view.LayoutInflater.from(this).inflate(R.layout.prayer_reminder_setup_enhanced, null);
        builder.setView(dialogView);
        builder.setCancelable(true);
        
        android.app.AlertDialog dialog = builder.create();
        dialog.show();
        
        initEditAlarmViews(dialogView, dialog, alarm);
    }
    
    private void initEditAlarmViews(android.view.View dialogView, android.app.AlertDialog dialog, SavedAlarm alarm) {
        android.widget.EditText reminderNameInput = dialogView.findViewById(R.id.reminder_name_input);
        com.google.android.material.button.MaterialButton timePickerButton = dialogView.findViewById(R.id.time_picker_button);
        android.widget.TextView selectedTimeDisplay = dialogView.findViewById(R.id.selected_time_display);
        com.google.android.material.button.MaterialButton saveReminderButton = dialogView.findViewById(R.id.save_reminder_button);
        com.google.android.material.button.MaterialButton cancelReminderButton = dialogView.findViewById(R.id.cancel_reminder_button);
        android.widget.ImageButton closeReminderButton = dialogView.findViewById(R.id.close_reminder_button);
        
        // Day selection chips
        com.google.android.material.chip.Chip sundayChip = dialogView.findViewById(R.id.sunday_chip);
        com.google.android.material.chip.Chip mondayChip = dialogView.findViewById(R.id.monday_chip);
        com.google.android.material.chip.Chip tuesdayChip = dialogView.findViewById(R.id.tuesday_chip);
        com.google.android.material.chip.Chip wednesdayChip = dialogView.findViewById(R.id.wednesday_chip);
        com.google.android.material.chip.Chip thursdayChip = dialogView.findViewById(R.id.thursday_chip);
        com.google.android.material.chip.Chip fridayChip = dialogView.findViewById(R.id.friday_chip);
        com.google.android.material.chip.Chip saturdayChip = dialogView.findViewById(R.id.saturday_chip);
        
        // Quick selection buttons
        com.google.android.material.button.MaterialButton weekdaysButton = dialogView.findViewById(R.id.weekdays_button);
        com.google.android.material.button.MaterialButton weekendsButton = dialogView.findViewById(R.id.weekends_button);
        com.google.android.material.button.MaterialButton allDaysButton = dialogView.findViewById(R.id.all_days_button);
        
        // Store chips in array for easy access
        com.google.android.material.chip.Chip[] dayChips = {
            sundayChip, mondayChip, tuesdayChip, wednesdayChip, 
            thursdayChip, fridayChip, saturdayChip
        };
        
        // Pre-fill with existing data
        reminderNameInput.setText(alarm.getName());
        selectedTimeDisplay.setText(alarm.getTime());
        
        // Set existing days
        String days = alarm.getDays();
        for (int i = 0; i < dayChips.length && i < days.length(); i++) {
            dayChips[i].setChecked(days.charAt(i) == '1');
        }
        
        // Time picker button click
        timePickerButton.setOnClickListener(v -> {
            String[] timeParts = alarm.getTime().split(":");
            int hour = Integer.parseInt(timeParts[0]);
            int minute = Integer.parseInt(timeParts[1]);
            
            android.app.TimePickerDialog timePickerDialog = new android.app.TimePickerDialog(this,
                (view, hourOfDay, minute1) -> {
                    selectedTimeDisplay.setText(String.format(java.util.Locale.getDefault(), "%02d:%02d", hourOfDay, minute1));
                },
                hour, minute, true);
            timePickerDialog.show();
        });
        
        // Quick selection buttons
        weekdaysButton.setOnClickListener(v -> {
            // Select Monday to Friday
            for (int i = 1; i <= 5; i++) {
                dayChips[i].setChecked(true);
            }
            dayChips[0].setChecked(false); // Sunday
            dayChips[6].setChecked(false); // Saturday
        });
        
        weekendsButton.setOnClickListener(v -> {
            // Select Saturday and Sunday
            dayChips[0].setChecked(true);  // Sunday
            dayChips[6].setChecked(true);   // Saturday
            for (int i = 1; i <= 5; i++) {
                dayChips[i].setChecked(false); // Monday to Friday
            }
        });
        
        allDaysButton.setOnClickListener(v -> {
            // Select all days
            for (com.google.android.material.chip.Chip chip : dayChips) {
                chip.setChecked(true);
            }
        });
        
        // Save button
        saveReminderButton.setOnClickListener(v -> {
            String reminderName = reminderNameInput.getText().toString().trim();
            String timeText = selectedTimeDisplay.getText().toString();
            
            if (android.text.TextUtils.isEmpty(reminderName)) {
                Toast.makeText(this, "Please enter alarm name", Toast.LENGTH_SHORT).show();
                return;
            }
            
            if (android.text.TextUtils.isEmpty(timeText)) {
                Toast.makeText(this, "Please select a time", Toast.LENGTH_SHORT).show();
                return;
            }
            
            // Get selected days
            StringBuilder daysBuilder = new StringBuilder();
            for (com.google.android.material.chip.Chip chip : dayChips) {
                daysBuilder.append(chip.isChecked() ? "1" : "0");
            }
            String selectedDays = daysBuilder.toString();
            
            // Check if at least one day is selected
            if (!selectedDays.contains("1")) {
                Toast.makeText(this, "Please select at least one day", Toast.LENGTH_SHORT).show();
                return;
            }
            
            updateAlarm(alarm, reminderName, timeText, selectedDays);
            dialog.dismiss();
        });
        
        // Cancel button
        cancelReminderButton.setOnClickListener(v -> dialog.dismiss());
        
        // Close button
        closeReminderButton.setOnClickListener(v -> dialog.dismiss());
    }
    
    private void updateAlarm(SavedAlarm alarm, String newName, String newTime, String newDays) {
        try {
            // Cancel existing alarm
            cancelAlarm(alarm.getId());
            
            // Update SharedPreferences
            SharedPreferences prefs = getSharedPreferences("saved_alarms", MODE_PRIVATE);
            SharedPreferences.Editor editor = prefs.edit();
            editor.putString("alarm_" + alarm.getId() + "_name", newName);
            editor.putString("alarm_" + alarm.getId() + "_time", newTime);
            editor.putString("alarm_" + alarm.getId() + "_days", newDays);
            editor.apply();
            
            // Set new alarm
            setAlarmForSavedAlarm(alarm.getId(), newName, newTime, newDays);
            
            // Update the alarm object
            alarm.setName(newName);
            alarm.setTime(newTime);
            alarm.setDays(newDays);
            
            // Refresh the list
            alarmsAdapter.notifyDataSetChanged();
            
            Toast.makeText(this, "Alarm updated successfully!", Toast.LENGTH_SHORT).show();
            
            Log.d("SavedAlarms", "Alarm updated: " + newName + " at " + newTime + " for days: " + newDays);
            
        } catch (Exception e) {
            Log.e("SavedAlarms", "Error updating alarm", e);
            Toast.makeText(this, "Error updating alarm", Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Refresh the list when returning from SetAlarmActivity
        loadSavedAlarms();
        setupRecyclerView();
    }
}
