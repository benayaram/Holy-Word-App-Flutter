package com.holywordapp;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import androidx.core.app.NotificationCompat;

public class PrayerReminderReceiver extends BroadcastReceiver {
    
    private static final String CHANNEL_ID = "prayer_reminders_channel";
    private static final int NOTIFICATION_ID = 2001;
    
    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        
        if (action != null) {
            handleNotificationAction(context, intent, action);
        } else {
            // Regular alarm triggered
            Log.d("PrayerReminder", "Prayer reminder alarm triggered");
            
            String reminderName = intent.getStringExtra("reminder_name");
            String reminderTime = intent.getStringExtra("reminder_time");
            
            if (reminderName == null) {
                reminderName = "Prayer Time";
            }
            
            // Launch Alarm Activity
            launchAlarmActivity(context, reminderName, reminderTime);
            
            // Also show notification as backup
            createNotificationChannel(context);
            showPrayerNotification(context, reminderName, reminderTime);
        }
    }
    
    private void handleNotificationAction(Context context, Intent intent, String action) {
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        
        switch (action) {
            case "SNOOZE_5":
                snoozeReminder(context, intent, 5);
                notificationManager.cancel(NOTIFICATION_ID);
                break;
            case "SNOOZE_15":
                snoozeReminder(context, intent, 15);
                notificationManager.cancel(NOTIFICATION_ID);
                break;
            case "SNOOZE_30":
                snoozeReminder(context, intent, 30);
                notificationManager.cancel(NOTIFICATION_ID);
                break;
            case "DISMISS":
                notificationManager.cancel(NOTIFICATION_ID);
                Log.d("PrayerReminder", "Prayer reminder dismissed");
                break;
        }
    }
    
    private void snoozeReminder(Context context, Intent intent, int minutes) {
        try {
            String reminderName = intent.getStringExtra("reminder_name");
            String reminderTime = intent.getStringExtra("reminder_time");
            
            // Create calendar for snooze time
            java.util.Calendar calendar = java.util.Calendar.getInstance();
            calendar.add(java.util.Calendar.MINUTE, minutes);
            
            // Create intent for snoozed alarm
            Intent snoozeIntent = new Intent(context, PrayerReminderReceiver.class);
            snoozeIntent.putExtra("reminder_name", reminderName);
            snoozeIntent.putExtra("reminder_time", reminderTime);
            
            android.app.PendingIntent snoozePendingIntent = android.app.PendingIntent.getBroadcast(context, 
                1000 + minutes, snoozeIntent, android.app.PendingIntent.FLAG_UPDATE_CURRENT | android.app.PendingIntent.FLAG_IMMUTABLE);
            
            // Set snooze alarm
            android.app.AlarmManager alarmManager = (android.app.AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
            alarmManager.set(android.app.AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(), snoozePendingIntent);
            
            Log.d("PrayerReminder", "Prayer reminder snoozed for " + minutes + " minutes");
            
        } catch (Exception e) {
            Log.e("PrayerReminder", "Error snoozing reminder", e);
        }
    }
    
    private void launchAlarmActivity(Context context, String reminderName, String reminderTime) {
        try {
            Intent alarmIntent = new Intent(context, AlarmActivity.class);
            alarmIntent.putExtra("reminder_name", reminderName);
            alarmIntent.putExtra("reminder_time", reminderTime);
            alarmIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | 
                               Intent.FLAG_ACTIVITY_CLEAR_TOP |
                               Intent.FLAG_ACTIVITY_SINGLE_TOP);
            
            context.startActivity(alarmIntent);
            
            Log.d("PrayerReminder", "Alarm activity launched: " + reminderName);
            
        } catch (Exception e) {
            Log.e("PrayerReminder", "Error launching alarm activity", e);
        }
    }
    
    private void createNotificationChannel(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Prayer Reminders",
                NotificationManager.IMPORTANCE_HIGH
            );
            channel.setDescription("Notifications for prayer reminders");
            channel.enableLights(true);
            channel.enableVibration(true);
            channel.setShowBadge(true);
            
            NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }
    
    private void showPrayerNotification(Context context, String reminderName, String reminderTime) {
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        
        // Create intent to open the app
        Intent intent = new Intent(context, com.holywordapp.dashboard.UserDashboardActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        
        // Create snooze intents
        Intent snooze5Intent = new Intent(context, PrayerReminderReceiver.class);
        snooze5Intent.setAction("SNOOZE_5");
        snooze5Intent.putExtra("reminder_name", reminderName);
        snooze5Intent.putExtra("reminder_time", reminderTime);
        PendingIntent snooze5PendingIntent = PendingIntent.getBroadcast(context, 1, snooze5Intent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        
        Intent snooze15Intent = new Intent(context, PrayerReminderReceiver.class);
        snooze15Intent.setAction("SNOOZE_15");
        snooze15Intent.putExtra("reminder_name", reminderName);
        snooze15Intent.putExtra("reminder_time", reminderTime);
        PendingIntent snooze15PendingIntent = PendingIntent.getBroadcast(context, 2, snooze15Intent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        
        Intent snooze30Intent = new Intent(context, PrayerReminderReceiver.class);
        snooze30Intent.setAction("SNOOZE_30");
        snooze30Intent.putExtra("reminder_name", reminderName);
        snooze30Intent.putExtra("reminder_time", reminderTime);
        PendingIntent snooze30PendingIntent = PendingIntent.getBroadcast(context, 3, snooze30Intent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        
        // Create dismiss intent
        Intent dismissIntent = new Intent(context, PrayerReminderReceiver.class);
        dismissIntent.setAction("DISMISS");
        PendingIntent dismissPendingIntent = PendingIntent.getBroadcast(context, 4, dismissIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        
        // Build notification
        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_alarm)
            .setContentTitle(context.getString(R.string.prayer_notification_title))
            .setContentText(String.format(context.getString(R.string.prayer_notification_text), reminderName))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(false)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(R.drawable.ic_access_time, context.getString(R.string.snooze_5_min), snooze5PendingIntent)
            .addAction(R.drawable.ic_access_time, context.getString(R.string.snooze_15_min), snooze15PendingIntent)
            .addAction(R.drawable.ic_access_time, context.getString(R.string.snooze_30_min), snooze30PendingIntent)
            .addAction(R.drawable.ic_close, context.getString(R.string.dismiss), dismissPendingIntent);
        
        notificationManager.notify(NOTIFICATION_ID, builder.build());
        
        Log.d("PrayerReminder", "Prayer notification shown: " + reminderName);
    }
    
    private void playPrayerSound(Context context) {
        try {
            // Get default notification sound
            Uri notificationSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
            
            // Play the sound
            MediaPlayer mediaPlayer = new MediaPlayer();
            mediaPlayer.setAudioStreamType(AudioManager.STREAM_NOTIFICATION);
            mediaPlayer.setDataSource(context, notificationSound);
            mediaPlayer.prepare();
            mediaPlayer.start();
            
            // Release after playing
            mediaPlayer.setOnCompletionListener(mp -> {
                mp.release();
                Log.d("PrayerReminder", "Prayer sound completed");
            });
            
            Log.d("PrayerReminder", "Prayer sound started");
            
        } catch (Exception e) {
            Log.e("PrayerReminder", "Error playing prayer sound", e);
        }
    }
}
