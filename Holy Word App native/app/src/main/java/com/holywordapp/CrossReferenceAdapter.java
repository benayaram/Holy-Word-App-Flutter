package com.holywordapp;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import android.widget.Button;

import java.util.List;

public class CrossReferenceAdapter extends RecyclerView.Adapter<CrossReferenceAdapter.CrossReferenceViewHolder> {

    private List<CrossReference.Reference> references;
    private Context context;
    private OnReferenceClickListener listener;

    public interface OnReferenceClickListener {
        void onReferenceClick(CrossReference.Reference reference);
    }

    public CrossReferenceAdapter(Context context, List<CrossReference.Reference> references, OnReferenceClickListener listener) {
        this.context = context;
        this.references = references;
        this.listener = listener;
    }

    @NonNull
    @Override
    public CrossReferenceViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_cross_reference, parent, false);
        return new CrossReferenceViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull CrossReferenceViewHolder holder, int position) {
        CrossReference.Reference reference = references.get(position);
        holder.bind(reference);
    }

    @Override
    public int getItemCount() {
        return references.size();
    }

    public void updateReferences(List<CrossReference.Reference> newReferences) {
        this.references = newReferences;
        notifyDataSetChanged();
    }

    class CrossReferenceViewHolder extends RecyclerView.ViewHolder {
        TextView tvReferenceType, tvReferenceLocation, tvReferenceText;
        Button btnViewReference;

        CrossReferenceViewHolder(@NonNull View itemView) {
            super(itemView);
            tvReferenceType = itemView.findViewById(R.id.tvReferenceType);
            tvReferenceLocation = itemView.findViewById(R.id.tvReferenceLocation);
            tvReferenceText = itemView.findViewById(R.id.tvReferenceText);
            btnViewReference = itemView.findViewById(R.id.btnViewReference);
        }

        void bind(CrossReference.Reference reference) {
            // Set reference type with color coding
            tvReferenceType.setText(reference.getTypeDisplayName());
            setTypeColor(reference.getType());

            // Set reference location
            tvReferenceLocation.setText(reference.getFormattedReference());

            // Set reference text
            String refText = reference.getText();
            if (refText != null && !refText.trim().isEmpty()) {
                tvReferenceText.setText(refText);
                tvReferenceText.setVisibility(View.VISIBLE);
            } else {
                tvReferenceText.setText("No text available");
                tvReferenceText.setVisibility(View.VISIBLE);
            }

            // Set click listener
            btnViewReference.setOnClickListener(v -> {
                if (listener != null) {
                    listener.onReferenceClick(reference);
                }
            });

            // Make entire item clickable
            itemView.setOnClickListener(v -> {
                if (listener != null) {
                    listener.onReferenceClick(reference);
                }
            });
        }

        private void setTypeColor(String type) {
            int colorRes;
            switch (type) {
                case "parallel":
                    colorRes = android.R.color.holo_blue_dark;
                    break;
                case "quotation":
                    colorRes = android.R.color.holo_green_dark;
                    break;
                case "allusion":
                    colorRes = android.R.color.holo_orange_dark;
                    break;
                case "theme":
                    colorRes = android.R.color.holo_purple;
                    break;
                case "prophecy":
                    colorRes = android.R.color.holo_red_dark;
                    break;
                case "fulfillment":
                    colorRes = android.R.color.holo_green_light;
                    break;
                default:
                    colorRes = android.R.color.darker_gray;
                    break;
            }
            tvReferenceType.setBackgroundTintList(android.content.res.ColorStateList.valueOf(context.getResources().getColor(colorRes)));
        }
    }
}

