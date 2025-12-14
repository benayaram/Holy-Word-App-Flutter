package com.holywordapp;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

public class NotesActivity extends AppCompatActivity implements NoteAdapter.NoteListener {

    private RecyclerView recyclerViewNotes;
    private NotesDBHelper dbHelper;
    private NoteAdapter noteAdapter;
    private TextView emptyView;
    private TextView notesCountView;
    private LinearLayout layoutEmptyState;
    private com.google.android.material.floatingactionbutton.FloatingActionButton fabAddNote;
    private com.google.android.material.button.MaterialButton btnCreateFirstNote;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_notes);

        // Set up toolbar
        androidx.appcompat.widget.Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setDisplayShowHomeEnabled(true);
        }

        recyclerViewNotes = findViewById(R.id.recyclerViewNotes);
        emptyView = findViewById(R.id.textViewEmptyNotes);
        notesCountView = findViewById(R.id.textViewNotesCount);
        layoutEmptyState = findViewById(R.id.layoutEmptyState);
        fabAddNote = findViewById(R.id.fabAddNote);
        btnCreateFirstNote = findViewById(R.id.btnCreateFirstNote);

        dbHelper = new NotesDBHelper(this);

        // Set up button click listeners
        fabAddNote.setOnClickListener(v -> showCreateNoteDialog());
        btnCreateFirstNote.setOnClickListener(v -> showCreateNoteDialog());

        loadNotes();
    }

    private void loadNotes() {
        List<Note> notes = dbHelper.getAllNotes();

        // Update notes count
        String countText = notes.size() + (notes.size() == 1 ? " Note" : " Notes");
        notesCountView.setText(countText);

        if (notes.isEmpty()) {
            recyclerViewNotes.setVisibility(View.GONE);
            layoutEmptyState.setVisibility(View.VISIBLE);
        } else {
            recyclerViewNotes.setVisibility(View.VISIBLE);
            layoutEmptyState.setVisibility(View.GONE);

            noteAdapter = new NoteAdapter(notes, this);
            recyclerViewNotes.setLayoutManager(new LinearLayoutManager(this));
            recyclerViewNotes.setAdapter(noteAdapter);
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_notes, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        int id = item.getItemId();

        if (id == android.R.id.home) {
            onBackPressed();
            return true;
        } else if (id == R.id.action_add_note) {
            showCreateNoteDialog();
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    private void showCreateNoteDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Create New Note");

        View view = LayoutInflater.from(this).inflate(R.layout.dialog_create_note, null);
        EditText titleEditText = view.findViewById(R.id.editTextNoteTitle);

        builder.setView(view);

        builder.setPositiveButton("Create", (dialog, which) -> {
            String title = titleEditText.getText().toString().trim();

            if (!title.isEmpty()) {
                Note newNote = new Note(0, title);
                long noteId = dbHelper.createNote(newNote);

                if (noteId > 0) {
                    Toast.makeText(this, "Note created", Toast.LENGTH_SHORT).show();
                    loadNotes();
                } else {
                    Toast.makeText(this, "Failed to create note", Toast.LENGTH_SHORT).show();
                }
            } else {
                Toast.makeText(this, "Title cannot be empty", Toast.LENGTH_SHORT).show();
            }
        });

        builder.setNegativeButton("Cancel", null);

        builder.show();
    }

    @Override
    public void onNoteClick(Note note) {
        Intent intent = new Intent(this, NoteDetailActivity.class);
        intent.putExtra("NOTE_ID", note.getId());
        startActivity(intent);
    }

    @Override
    public void onEditNoteClick(Note note) {
        showEditNoteDialog(note);
    }

    @Override
    public void onDeleteNoteClick(Note note) {
        new AlertDialog.Builder(this)
                .setTitle("Delete Note")
                .setMessage("Are you sure you want to delete this note?")
                .setPositiveButton("Delete", (dialog, which) -> {
                    if (dbHelper.deleteNote(note.getId())) {
                        Toast.makeText(this, "Note deleted", Toast.LENGTH_SHORT).show();
                        loadNotes();
                    } else {
                        Toast.makeText(this, "Failed to delete note", Toast.LENGTH_SHORT).show();
                    }
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    private void showEditNoteDialog(Note note) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Edit Note Title");

        View view = LayoutInflater.from(this).inflate(R.layout.dialog_create_note, null);
        EditText titleEditText = view.findViewById(R.id.editTextNoteTitle);
        titleEditText.setText(note.getTitle());

        builder.setView(view);

        builder.setPositiveButton("Save", (dialog, which) -> {
            String title = titleEditText.getText().toString().trim();

            if (!title.isEmpty()) {
                note.setTitle(title);
                int result = dbHelper.updateNoteTitle(note);

                if (result > 0) {
                    Toast.makeText(this, "Note updated", Toast.LENGTH_SHORT).show();
                    loadNotes();
                } else {
                    Toast.makeText(this, "Failed to update note", Toast.LENGTH_SHORT).show();
                }
            } else {
                Toast.makeText(this, "Title cannot be empty", Toast.LENGTH_SHORT).show();
            }
        });

        builder.setNegativeButton("Cancel", null);

        builder.show();
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadNotes(); // Refresh notes when returning to this activity
    }
}