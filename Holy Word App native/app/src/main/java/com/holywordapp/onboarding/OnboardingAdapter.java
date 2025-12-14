package com.holywordapp.onboarding;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.TextView;

import com.google.android.material.button.MaterialButton;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.holywordapp.R;

public class OnboardingAdapter extends RecyclerView.Adapter<OnboardingAdapter.OnboardingViewHolder> {

    private Context context;
    private OnboardingScreen[] screens;

    public OnboardingAdapter(Context context) {
        this.context = context;
        updateScreens();
    }
    
    public void updateScreens() {
        this.screens = new OnboardingScreen[]{
                new OnboardingScreen(
                        R.mipmap.ic_launcher,
                        context.getString(R.string.onboarding_language_title),
                        context.getString(R.string.onboarding_language_description),
                        OnboardingScreen.ScreenType.LANGUAGE_SELECTION
                ),
                new OnboardingScreen(
                        R.mipmap.ic_launcher,
                        context.getString(R.string.onboarding_welcome_title),
                        context.getString(R.string.onboarding_welcome_description),
                        OnboardingScreen.ScreenType.WELCOME
                ),
                new OnboardingScreen(
                        R.mipmap.ic_launcher,
                        context.getString(R.string.onboarding_video_title),
                        context.getString(R.string.onboarding_video_description),
                        OnboardingScreen.ScreenType.VIDEO_SHOWCASE
                ),
                new OnboardingScreen(
                        R.mipmap.ic_launcher,
                        context.getString(R.string.onboarding_ready_title),
                        context.getString(R.string.onboarding_ready_description),
                        OnboardingScreen.ScreenType.READY_TO_BEGIN
                )
        };
    }

    @NonNull
    @Override
    public OnboardingViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_onboarding_screen, parent, false);
        return new OnboardingViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull OnboardingViewHolder holder, int position) {
        OnboardingScreen screen = screens[position];
        holder.bind(screen);
    }

    @Override
    public int getItemCount() {
        return screens.length;
    }

    static class OnboardingViewHolder extends RecyclerView.ViewHolder {
        private ImageView imageView;
        private TextView titleTextView;
        private TextView descriptionTextView;
        private LinearLayout languageSelectionContainer;
        private RadioButton englishRadio;
        private RadioButton teluguRadio;
        private MaterialButton playVideoButton;

        public OnboardingViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.onboarding_image);
            titleTextView = itemView.findViewById(R.id.onboarding_title);
            descriptionTextView = itemView.findViewById(R.id.onboarding_description);
            languageSelectionContainer = itemView.findViewById(R.id.language_selection_container);
            englishRadio = itemView.findViewById(R.id.english_radio);
            teluguRadio = itemView.findViewById(R.id.telugu_radio);
            playVideoButton = itemView.findViewById(R.id.play_video_button);
        }

        public void bind(OnboardingScreen screen) {
            imageView.setImageResource(screen.getImageRes());
            titleTextView.setText(screen.getTitle());
            descriptionTextView.setText(screen.getDescription());

            // Apply Telugu-friendly fonts when locale is Telugu
            java.util.Locale current = itemView.getResources().getConfiguration().getLocales().get(0);
            if ("te".equals(current.getLanguage())) {
                try {
                    titleTextView.setTypeface(android.graphics.Typeface.createFromAsset(itemView.getContext().getAssets(), "font/ramabhadra_regular.ttf"));
                    descriptionTextView.setTypeface(android.graphics.Typeface.createFromAsset(itemView.getContext().getAssets(), "font/mandali_regular.ttf"));
                } catch (Exception ignored) { }
            }
            
            // Show language selection only for the first screen
            if (screen.getScreenType() == OnboardingScreen.ScreenType.LANGUAGE_SELECTION) {
                languageSelectionContainer.setVisibility(View.VISIBLE);
                playVideoButton.setVisibility(View.GONE);
                setupLanguageSelection();
            } else if (screen.getScreenType() == OnboardingScreen.ScreenType.VIDEO_SHOWCASE) {
                languageSelectionContainer.setVisibility(View.GONE);
                playVideoButton.setVisibility(View.VISIBLE);
                setupVideoButton();
            } else {
                languageSelectionContainer.setVisibility(View.GONE);
                playVideoButton.setVisibility(View.GONE);
            }

            // Ensure bottom content is not obscured by the footer by adding bottom padding dynamically
            View root = (View) itemView.getParent();
            if (root != null) {
                int extraPadding = (int) (itemView.getResources().getDisplayMetrics().density * 96);
                itemView.setPadding(itemView.getPaddingLeft(), itemView.getPaddingTop(), itemView.getPaddingRight(), extraPadding);
            }
        }
        
        private void setupLanguageSelection() {
            // Set up radio button group behavior
            englishRadio.setOnCheckedChangeListener((buttonView, isChecked) -> {
                if (isChecked) {
                    teluguRadio.setChecked(false);
                    // Notify adapter about language selection
                    if (itemView.getContext() instanceof OnboardingActivity) {
                        ((OnboardingActivity) itemView.getContext()).setSelectedLanguage("en");
                    }
                }
            });
            
            teluguRadio.setOnCheckedChangeListener((buttonView, isChecked) -> {
                if (isChecked) {
                    englishRadio.setChecked(false);
                    // Notify adapter about language selection
                    if (itemView.getContext() instanceof OnboardingActivity) {
                        ((OnboardingActivity) itemView.getContext()).setSelectedLanguage("te");
                    }
                }
            });
        }
        
        private void setupVideoButton() {
            playVideoButton.setOnClickListener(v -> {
                Intent intent = new Intent(itemView.getContext(), VideoPopupActivity.class);
                itemView.getContext().startActivity(intent);
            });
        }
    }
}
