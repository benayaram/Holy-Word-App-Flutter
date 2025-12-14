package com.holywordapp;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;
import java.util.ArrayList;
import java.util.List;

public class ChapterAdapter extends RecyclerView.Adapter<ChapterAdapter.ChapterViewHolder> {

    private List<String> chapterList = new ArrayList<>();
    private int playingChapterIndex = -1; // -1 indicates nothing is playing initially
    private final OnChapterClickListener listener;
    private final Context context;
    private final Drawable playingIndicator;
    private final Drawable defaultIndicator;
    private final int highlightColor;
    private final Drawable defaultBackground;


    public interface OnChapterClickListener {
        void onChapterClick(int position);
    }

    public ChapterAdapter(Context context, OnChapterClickListener listener) {
        this.context = context;
        this.listener = listener;
        // Load resources once
        this.playingIndicator = ContextCompat.getDrawable(context, R.drawable.ic_play);
        this.defaultIndicator = ContextCompat.getDrawable(context, R.drawable.ic_play);
        this.highlightColor = ContextCompat.getColor(context, R.color.bible_navy); // Define in colors.xml
        this.defaultBackground = ContextCompat.getDrawable(context, R.drawable.bg_round_button); // Define selector drawable
    }

    public void setChapters(List<String> chapters) {
        this.chapterList = chapters;
        this.playingChapterIndex = -1; // Reset playing index when list changes
        notifyDataSetChanged();
    }
    private List<String> chapters;

    public void updateChapterList(List<String> chapters) {
        this.chapters = chapters;
        notifyDataSetChanged();
    }
    public void updatePlayingChapter(int index) {
        int oldPlayingIndex = this.playingChapterIndex;
        this.playingChapterIndex = index; // index is 0-based

        // Update previously playing item (if any)
        if (oldPlayingIndex >= 0 && oldPlayingIndex < getItemCount()) {
            notifyItemChanged(oldPlayingIndex);
        }
        // Update newly playing item (if any)
        if (playingChapterIndex >= 0 && playingChapterIndex < getItemCount()) {
            notifyItemChanged(playingChapterIndex);
        }
    }

    @NonNull
    @Override
    public ChapterViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.list_item_chapter, parent, false);
        return new ChapterViewHolder(view, listener);
    }

    @Override
    public void onBindViewHolder(@NonNull ChapterViewHolder holder, int position) {
        String chapterName = chapterList.get(position);
        holder.chapterNameTextView.setText(chapterName);

        // If this chapter is currently playing, set the indicator and highlight the background
        if (position == playingChapterIndex) {
            holder.playingIndicatorImageView.setImageDrawable(playingIndicator);
            holder.itemView.setBackgroundColor(highlightColor); // Highlight background with color
        } else {
            holder.playingIndicatorImageView.setImageDrawable(defaultIndicator);
            holder.itemView.setBackground(defaultBackground.getConstantState().newDrawable().mutate()); // Ensure fresh background drawable
        }
    }

    @Override
    public int getItemCount() {
        return chapterList.size();
    }

    static class ChapterViewHolder extends RecyclerView.ViewHolder {
        ImageView playingIndicatorImageView;
        TextView chapterNameTextView;

        ChapterViewHolder(@NonNull View itemView, OnChapterClickListener listener) {
            super(itemView);
            playingIndicatorImageView = itemView.findViewById(R.id.playingIndicatorImageView);
            chapterNameTextView = itemView.findViewById(R.id.chapterNameTextView);

            // Setting up the click listener for each item
            itemView.setOnClickListener(v -> {
                int position = getAdapterPosition(); // Use getAdapterPosition for compatibility
                if (position != RecyclerView.NO_POSITION && listener != null) {
                    listener.onChapterClick(position);
                }
            });
        }
    }
}
