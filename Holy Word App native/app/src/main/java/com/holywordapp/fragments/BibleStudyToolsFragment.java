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
import com.holywordapp.BibleGatewayActivity;
import com.holywordapp.BibleActivity;
import com.holywordapp.BibleDictionaryActivity;
import com.holywordapp.CrossReferencesActivity;
import com.holywordapp.R;

public class BibleStudyToolsFragment extends Fragment {

    private MaterialCardView bibleCard, crossReferencesCard, audioBibleCard, powerfulSearchCard, bibleDictionaryCard;
    private TextView welcomeText;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_bible_study_tools, container, false);
        
        initViews(view);
        setupListeners();
        
        return view;
    }

    private void initViews(View view) {
        welcomeText = view.findViewById(R.id.welcome_text);
        bibleCard = view.findViewById(R.id.bible_card);
        crossReferencesCard = view.findViewById(R.id.cross_references_card);
        audioBibleCard = view.findViewById(R.id.audio_bible_card);
        powerfulSearchCard = view.findViewById(R.id.powerful_search_card);
        bibleDictionaryCard = view.findViewById(R.id.bible_dictionary_card);
    }

    private void setupListeners() {
        bibleCard.setOnClickListener(v -> {
            Intent intent = new Intent(getActivity(), BibleActivity.class);
            startActivity(intent);
        });
        
        crossReferencesCard.setOnClickListener(v -> {
            Intent intent = new Intent(getActivity(), CrossReferencesActivity.class);
            startActivity(intent);
        });
        
        audioBibleCard.setOnClickListener(v -> {
            Intent intent = new Intent(getActivity(), AudioBibleActivity.class);
            startActivity(intent);
        });
        
        powerfulSearchCard.setOnClickListener(v -> {
            Intent intent = new Intent(getActivity(), BibleGatewayActivity.class);
            startActivity(intent);
        });
        
        bibleDictionaryCard.setOnClickListener(v -> {
            Intent intent = new Intent(getActivity(), BibleDictionaryActivity.class);
            startActivity(intent);
        });
    }

    private void showSampleText(String title, String content) {
        // Create a simple dialog to show sample text
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(getContext());
        builder.setTitle(title);
        builder.setMessage(content);
        builder.setPositiveButton("OK", (dialog, which) -> dialog.dismiss());
        builder.setNegativeButton("Launch Feature", (dialog, which) -> {
            Toast.makeText(getContext(), title + " - Feature coming soon!", Toast.LENGTH_SHORT).show();
            dialog.dismiss();
        });
        builder.show();
    }
}
