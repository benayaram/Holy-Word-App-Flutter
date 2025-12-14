package com.holywordapp.adapters;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.card.MaterialCardView;
import com.google.android.material.switchmaterial.SwitchMaterial;
import com.holywordapp.R;
import com.holywordapp.models.SavedAlarm;

import java.util.List;

public class SavedAlarmsAdapter extends RecyclerView.Adapter<SavedAlarmsAdapter.AlarmViewHolder> {
    
    private List<SavedAlarm> alarms;
    private OnAlarmActionListener listener;
    
    public interface OnAlarmActionListener {
        void onEditAlarm(SavedAlarm alarm);
        void onDeleteAlarm(SavedAlarm alarm);
        void onToggleAlarm(SavedAlarm alarm);
    }
    
    public SavedAlarmsAdapter(List<SavedAlarm> alarms, OnAlarmActionListener listener) {
        this.alarms = alarms;
        this.listener = listener;
    }
    
    @NonNull
    @Override
    public AlarmViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_saved_alarm, parent, false);
        return new AlarmViewHolder(view);
    }
    
    @Override
    public void onBindViewHolder(@NonNull AlarmViewHolder holder, int position) {
        SavedAlarm alarm = alarms.get(position);
        holder.bind(alarm);
    }
    
    @Override
    public int getItemCount() {
        return alarms.size();
    }
    
    class AlarmViewHolder extends RecyclerView.ViewHolder {
        private MaterialCardView alarmCard;
        private TextView alarmNameText;
        private TextView alarmTimeText;
        private TextView alarmDaysText;
        private SwitchMaterial alarmSwitch;
        private ImageButton editButton;
        private ImageButton deleteButton;
        
        public AlarmViewHolder(@NonNull View itemView) {
            super(itemView);
            
            alarmCard = itemView.findViewById(R.id.alarm_card);
            alarmNameText = itemView.findViewById(R.id.alarm_name_text);
            alarmTimeText = itemView.findViewById(R.id.alarm_time_text);
            alarmDaysText = itemView.findViewById(R.id.alarm_days_text);
            alarmSwitch = itemView.findViewById(R.id.alarm_switch);
            editButton = itemView.findViewById(R.id.edit_button);
            deleteButton = itemView.findViewById(R.id.delete_button);
        }
        
        public void bind(SavedAlarm alarm) {
            alarmNameText.setText(alarm.getName());
            alarmTimeText.setText(alarm.getTime());
            alarmDaysText.setText(alarm.getDaysText());
            alarmSwitch.setChecked(alarm.isActive());
            
            // Set click listeners
            alarmSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
                if (listener != null) {
                    listener.onToggleAlarm(alarm);
                }
            });
            
            editButton.setOnClickListener(v -> {
                if (listener != null) {
                    listener.onEditAlarm(alarm);
                }
            });
            
            deleteButton.setOnClickListener(v -> {
                if (listener != null) {
                    listener.onDeleteAlarm(alarm);
                }
            });
            
            // Update card appearance based on active state
            if (alarm.isActive()) {
                alarmCard.setCardBackgroundColor(itemView.getContext().getResources().getColor(R.color.background_card));
                alarmCard.setStrokeColor(itemView.getContext().getResources().getColor(R.color.primary));
                alarmCard.setStrokeWidth(2);
            } else {
                alarmCard.setCardBackgroundColor(itemView.getContext().getResources().getColor(R.color.background_card));
                alarmCard.setStrokeColor(itemView.getContext().getResources().getColor(R.color.text_secondary));
                alarmCard.setStrokeWidth(1);
            }
        }
    }
}

