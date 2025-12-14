package com.holywordapp;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import com.google.android.material.button.MaterialButton;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

public class NoteAdapter extends RecyclerView.Adapter<NoteAdapter.NoteViewHolder> {

    private List<Note> notes;
    private NoteListener listener;

    public interface NoteListener {
        void onNoteClick(Note note);
        void onEditNoteClick(Note note);
        void onDeleteNoteClick(Note note);
    }

    public NoteAdapter(List<Note> notes, NoteListener listener) {
        this.notes = notes;
        this.listener = listener;
    }

    @NonNull
    @Override
    public NoteViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_note, parent, false);
        return new NoteViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull NoteViewHolder holder, int position) {
        Note note = notes.get(position);
        holder.titleTextView.setText(note.getTitle());

        // Show how many verses are in this note
        int verseCount = note.getVerseReferences().size();
        holder.verseCountTextView.setText(verseCount + " verse" + (verseCount != 1 ? "s" : ""));

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onNoteClick(note);
            }
        });

        holder.editButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onEditNoteClick(note);
            }
        });

        holder.deleteButton.setOnClickListener(v -> {
            if (listener != null) {
                listener.onDeleteNoteClick(note);
            }
        });
    }

    @Override
    public int getItemCount() {
        return notes.size();
    }

    static class NoteViewHolder extends RecyclerView.ViewHolder {
        TextView titleTextView;
        TextView verseCountTextView;
        MaterialButton editButton;
        MaterialButton deleteButton;

        NoteViewHolder(@NonNull View itemView) {
            super(itemView);
            titleTextView = itemView.findViewById(R.id.textViewNoteTitle);
            verseCountTextView = itemView.findViewById(R.id.textViewVerseCount);
            editButton = itemView.findViewById(R.id.buttonEditNote);
            deleteButton = itemView.findViewById(R.id.buttonDeleteNote);
        }
    }
}