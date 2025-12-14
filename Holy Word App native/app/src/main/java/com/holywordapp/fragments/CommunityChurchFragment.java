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

public class CommunityChurchFragment extends Fragment {

    private MaterialCardView churchEventsCard, prayerRequestsCard, communityGroupsCard, churchDirectoryCard, announcementsCard;
    private TextView welcomeText;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_community_church, container, false);
        
        initViews(view);
        setupListeners();
        
        return view;
    }

    private void initViews(View view) {
        welcomeText = view.findViewById(R.id.welcome_text);
        churchEventsCard = view.findViewById(R.id.church_events_card);
        prayerRequestsCard = view.findViewById(R.id.prayer_requests_card);
        communityGroupsCard = view.findViewById(R.id.community_groups_card);
        churchDirectoryCard = view.findViewById(R.id.church_directory_card);
        announcementsCard = view.findViewById(R.id.announcements_card);
    }

    private void setupListeners() {
        churchEventsCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Church Events - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        prayerRequestsCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Prayer Requests - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        communityGroupsCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Community Groups - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        churchDirectoryCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Church Directory - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
        
        announcementsCard.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Announcements - Coming Soon!", Toast.LENGTH_SHORT).show();
        });
    }
}
