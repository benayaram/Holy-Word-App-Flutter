package com.holywordapp;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

public class VerseReferenceAdapter extends RecyclerView.Adapter<VerseReferenceAdapter.VerseReferenceViewHolder> {

    private List<VerseReference> verseReferences;
    private VerseReferenceListener listener;

    public interface VerseReferenceListener {
        void onVerseReferenceClick(VerseReference verseReference);
        void onDeleteVerseReferenceClick(VerseReference verseReference);
    }

    public VerseReferenceAdapter(List<VerseReference> verseReferences, VerseReferenceListener listener) {
        this.verseReferences = verseReferences;
        this.listener = listener;
    }

    @NonNull
    @Override
    public VerseReferenceViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_verse_reference, parent, false);
        return new VerseReferenceViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull VerseReferenceViewHolder holder, int position) {
        VerseReference reference = verseReferences.get(position);

        holder.referenceTextView.setText(reference.getReference());
        holder.referenceTextView.setTextColor(Color.parseColor("#3F51B5")); // Primary color

        holder.verseTextView.setText(reference.getVerseText());

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onVerseReferenceClick(reference);
            }
        });

        holder.deleteButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onDeleteVerseReferenceClick(reference);
            }
        });
    }

    @Override
    public int getItemCount() {
        return verseReferences.size();
    }

    static class VerseReferenceViewHolder extends RecyclerView.ViewHolder {
        TextView referenceTextView;
        TextView verseTextView;
        ImageButton deleteButton;

        VerseReferenceViewHolder(@NonNull View itemView) {
            super(itemView);
            referenceTextView = itemView.findViewById(R.id.textViewVerseReference);
            verseTextView = itemView.findViewById(R.id.textViewVerseText);
            deleteButton = itemView.findViewById(R.id.buttonDeleteReference);
        }
    }
}