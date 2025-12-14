package com.holywordapp.fragments;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.google.android.material.card.MaterialCardView;
import com.holywordapp.R;

public class SermonsTeachingsFragment extends Fragment {

    private MaterialCardView sermonLibraryCard, teachingSeriesCard, videoSermonsCard, audioSermonsCard, notesCard;
    private TextView welcomeText;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_sermons_teachings, container, false);
        
        initViews(view);
        setupListeners();
        
        return view;
    }

    private void initViews(View view) {
        welcomeText = view.findViewById(R.id.welcome_text);
        sermonLibraryCard = view.findViewById(R.id.sermon_library_card);
        teachingSeriesCard = view.findViewById(R.id.teaching_series_card);
        videoSermonsCard = view.findViewById(R.id.video_sermons_card);
        audioSermonsCard = view.findViewById(R.id.audio_sermons_card);
        notesCard = view.findViewById(R.id.notes_card);
    }

    private void setupListeners() {
        sermonLibraryCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Sermon Library - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        teachingSeriesCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Teaching Series - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        videoSermonsCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Video Sermons - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        audioSermonsCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Audio Sermons - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        notesCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Sermon Notes - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
    }
}
