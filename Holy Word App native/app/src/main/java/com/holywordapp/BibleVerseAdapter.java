package com.holywordapp;

import android.app.AlertDialog;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class BibleVerseAdapter extends RecyclerView.Adapter<BibleVerseAdapter.VerseViewHolder> {

    private List<BibleVerse> verses;
    private int highlightedPosition = -1;
    private OnVerseLongClickListener longClickListener;
    private Set<Integer> selectedPositions = new HashSet<>();
    private OnSelectionChangedListener selectionChangedListener;
    private boolean selectionMode = false;
    private List<Integer> highlightColors;
    private int[] availableColors = new int[] {
        0xFFFFFF00, // Yellow
        0xFF00FF00, // Green
        0xFF00FFFF, // Cyan
        0xFFFFA500, // Orange
        0xFFFF69B4, // Pink
        0xFF87CEEB, // Light Blue
        0xFFFFFFFF  // White (no highlight)
    };
    private OnAddNoteClickListener addNoteClickListener;
    private OnHighlightColorChangedListener highlightColorChangedListener;

    public interface OnVerseLongClickListener {
        // Changed to return boolean instead of void
        boolean onVerseLongClick(BibleVerse verse, int position);
    }

    public interface OnSelectionChangedListener {
        void onSelectionChanged(Set<Integer> selectedPositions);
    }

    public interface OnAddNoteClickListener {
        void onAddNoteClick(BibleVerse verse, int position);
    }
    public interface OnHighlightColorChangedListener {
        void onHighlightColorChanged(BibleVerse verse, int position, int color);
    }

    public BibleVerseAdapter(List<BibleVerse> verses) {
        this.verses = verses;
        this.highlightColors = new java.util.ArrayList<>();
        for (int i = 0; i < verses.size(); i++) highlightColors.add(0xFFFFFFFF); // Default: no highlight
    }

    public void setOnVerseLongClickListener(OnVerseLongClickListener listener) {
        this.longClickListener = listener;
    }

    public void setOnSelectionChangedListener(OnSelectionChangedListener listener) {
        this.selectionChangedListener = listener;
    }

    public void setOnAddNoteClickListener(OnAddNoteClickListener listener) {
        this.addNoteClickListener = listener;
    }
    public void setOnHighlightColorChangedListener(OnHighlightColorChangedListener listener) {
        this.highlightColorChangedListener = listener;
    }

    public void highlightPosition(int position) {
        int oldPosition = highlightedPosition;
        highlightedPosition = position;

        if (oldPosition >= 0) {
            notifyItemChanged(oldPosition);
        }

        if (highlightedPosition >= 0) {
            notifyItemChanged(highlightedPosition);
        }
    }

    // Remove highlight color dialog and listeners from the adapter
    // Add a method to set highlight color for a verse by position
    public void setHighlightColor(int position, int color) {
        if (position >= 0 && position < highlightColors.size()) {
            highlightColors.set(position, color);
            notifyItemChanged(position);
        }
    }
    public void setHighlightColors(List<Integer> colors) {
        if (colors.size() == highlightColors.size()) {
            for (int i = 0; i < colors.size(); i++) {
                highlightColors.set(i, colors.get(i));
            }
            notifyDataSetChanged();
        }
    }

    @NonNull
    @Override
    public VerseViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_bible_verse, parent, false);
        return new VerseViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull VerseViewHolder holder, int position) {
        BibleVerse verse = verses.get(position);
        holder.verseNumberTextView.setText(String.valueOf(verse.verseNum));
        holder.verseTextTextView.setText(verse.verseText);

        // Highlight if selected
        if (selectedPositions.contains(position)) {
            holder.itemView.setBackgroundColor(Color.parseColor("#B3DFFC")); // light blue
        } else if (position == highlightedPosition) {
            holder.itemView.setBackgroundColor(Color.LTGRAY);
        } else {
            holder.itemView.setBackgroundColor(highlightColors.get(position));
        }

        holder.itemView.setOnClickListener(v -> {
            // Normal click for selection
            if (selectionMode) {
                toggleSelection(position);
            } else {
                toggleSelection(position);
            }
        });

        holder.itemView.setOnLongClickListener(null); // Disable long click
    }

    private void toggleSelection(int position) {
        if (selectedPositions.contains(position)) {
            selectedPositions.remove(position);
        } else {
            selectedPositions.add(position);
        }
        notifyItemChanged(position);
        if (selectionChangedListener != null) {
            selectionChangedListener.onSelectionChanged(selectedPositions);
        }
        // Exit selection mode if none selected
        if (selectedPositions.isEmpty()) {
            selectionMode = false;
        }
    }

    public Set<Integer> getSelectedPositions() {
        return selectedPositions;
    }

    public List<BibleVerse> getSelectedVerses() {
        List<BibleVerse> selected = new java.util.ArrayList<>();
        for (int pos : selectedPositions) {
            if (pos >= 0 && pos < verses.size()) {
                selected.add(verses.get(pos));
            }
        }
        return selected;
    }

    public void clearSelection() {
        Set<Integer> oldSelection = new HashSet<>(selectedPositions);
        selectedPositions.clear();
        selectionMode = false;
        for (int pos : oldSelection) {
            notifyItemChanged(pos);
        }
        if (selectionChangedListener != null) {
            selectionChangedListener.onSelectionChanged(selectedPositions);
        }
    }

    public void highlightVerseTemporarily(int position) {
        if (position >= 0 && position < verses.size()) {
            // Temporarily highlight the verse
            int oldHighlighted = highlightedPosition;
            highlightedPosition = position;
            
            if (oldHighlighted >= 0) {
                notifyItemChanged(oldHighlighted);
            }
            notifyItemChanged(position);
            
            // Remove highlight after 3 seconds
            new android.os.Handler().postDelayed(() -> {
                if (highlightedPosition == position) {
                    highlightedPosition = -1;
                    notifyItemChanged(position);
                }
            }, 3000);
        }
    }

    @Override
    public int getItemCount() {
        return verses.size();
    }

    static class VerseViewHolder extends RecyclerView.ViewHolder {
        TextView verseNumberTextView;
        TextView verseTextTextView;

        VerseViewHolder(@NonNull View itemView) {
            super(itemView);
            verseNumberTextView = itemView.findViewById(R.id.textViewVerseNumber);
            verseTextTextView = itemView.findViewById(R.id.textViewVerseText);
        }
    }
}