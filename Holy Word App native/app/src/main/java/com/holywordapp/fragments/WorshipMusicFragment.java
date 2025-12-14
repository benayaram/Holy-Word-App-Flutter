package com.holywordapp.fragments;

import android.content.Intent;
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
import com.holywordapp.AudioBibleActivity;
import com.holywordapp.R;

public class WorshipMusicFragment extends Fragment {

    private MaterialCardView hymnsCard, worshipSongsCard, audioBibleCard, musicPlayerCard, playlistsCard;
    private TextView welcomeText;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_worship_music, container, false);
        
        initViews(view);
        setupListeners();
        
        return view;
    }

    private void initViews(View view) {
        welcomeText = view.findViewById(R.id.welcome_text);
        hymnsCard = view.findViewById(R.id.hymns_card);
        worshipSongsCard = view.findViewById(R.id.worship_songs_card);
        audioBibleCard = view.findViewById(R.id.audio_bible_card);
        musicPlayerCard = view.findViewById(R.id.music_player_card);
        playlistsCard = view.findViewById(R.id.playlists_card);
    }

    private void setupListeners() {
        hymnsCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Hymns - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        worshipSongsCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Worship Songs - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        audioBibleCard.setOnClickListener(v -> {
            Intent intent = new Intent(getActivity(), AudioBibleActivity.class);
            startActivity(intent);
        });
        
        musicPlayerCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Music Player - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        playlistsCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Playlists - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
    }
}
