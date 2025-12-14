#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cross References to JSON Converter
Converts cross references from text format to JSON for Bible activity navigation
"""

import json
import re
from collections import defaultdict

# Book name mapping from English abbreviations to Telugu names (as used in Bible activity)
BOOK_NAME_MAPPING = {
    "Gen": "ఆదికాండము",
    "Exod": "నిర్గమకాండము", 
    "Lev": "లేవీయకాండము",
    "Num": "సంఖ్యాకాండము",
    "Deut": "ద్వితీయోపదేశకాండమ",
    "Josh": "యెహొషువ",
    "Judg": "న్యాయాధిపతులు",
    "Ruth": "రూతు",
    "1Sam": "సమూయేలు మొదటి గ్రంథము",
    "2Sam": "సమూయేలు రెండవ గ్రంథము",
    "1Kgs": "రాజులు మొదటి గ్రంథము",
    "2Kgs": "రాజులు రెండవ గ్రంథము",
    "1Chr": "దినవృత్తాంతములు మొదటి గ్రంథము",
    "2Chr": "దినవృత్తాంతములు రెండవ గ్రంథము",
    "Ezra": "ఎజ్రా",
    "Neh": "నెహెమ్యా",
    "Esth": "ఎస్తేరు",
    "Job": "యోబు గ్రంథము",
    "Ps": "కీర్తనల గ్రంథము",
    "Prov": "సామెతలు",
    "Eccl": "ప్రసంగి",
    "Song": "పరమగీతము",
    "Isa": "యెషయా గ్రంథము",
    "Jer": "యిర్మీయా",
    "Lam": "విలాపవాక్యములు",
    "Ezek": "యెహెజ్కేలు",
    "Dan": "దానియేలు",
    "Hos": "హొషేయ",
    "Joel": "యోవేలు",
    "Amos": "ఆమోసు",
    "Obad": "ఓబద్యా",
    "Jonah": "యోనా",
    "Mic": "మీకా",
    "Nah": "నహూము",
    "Hab": "హబక్కూకు",
    "Zeph": "జెఫన్యా",
    "Hag": "హగ్గయి",
    "Zech": "జెకర్యా",
    "Mal": "మలాకీ",
    "Matt": "మత్తయి సువార్త",
    "Mark": "మార్కు సువార్త",
    "Luke": "లూకా సువార్త",
    "John": "యోహాను సువార్త",
    "Acts": "అపొస్తలుల కార్యములు",
    "Rom": "రోమీయులకు",
    "1Cor": "1 కొరింథీయులకు",
    "2Cor": "2 కొరింథీయులకు",
    "Gal": "గలతీయులకు",
    "Eph": "ఎఫెసీయులకు",
    "Phil": "ఫిలిప్పీయులకు",
    "Col": "కొలొస్సయులకు",
    "1Thess": "1 థెస్సలొనీకయులకు",
    "2Thess": "2 థెస్సలొనీకయులకు",
    "1Tim": "1 తిమోతికి",
    "2Tim": "2 తిమోతికి",
    "Titus": "తీతుకు",
    "Phlm": "ఫిలేమోనుకు",
    "Heb": "హెబ్రీయులకు",
    "Jas": "యాకోబు",
    "1Pet": "1 పేతురు",
    "2Pet": "2 పేతురు",
    "1John": "1 యోహాను",
    "2John": "2 యోహాను",
    "3John": "3 యోహాను",
    "Jude": "యూదా",
    "Rev": "ప్రకటన గ్రంథము"
}

def convert_english_to_telugu_book_name(english_name):
    """Convert English book abbreviation to Telugu book name"""
    return BOOK_NAME_MAPPING.get(english_name, english_name)

def parse_verse_reference(verse_ref):
    """Parse verse reference like 'Gen.1.1' or 'John.1.1-John.1.3'"""
    references = []
    
    # Handle verse ranges (e.g., "John.1.1-John.1.3")
    if '-' in verse_ref:
        range_parts = verse_ref.split('-')
        if len(range_parts) == 2:
            start_verse = range_parts[0].strip()
            end_verse = range_parts[1].strip()
            
            # Parse start and end verses
            start_ref = parse_single_verse(start_verse)
            end_ref = parse_single_verse(end_verse)
            
            if start_ref and end_ref:
                # Check if same book and chapter
                if start_ref['book'] == end_ref['book'] and start_ref['chapter'] == end_ref['chapter']:
                    # Expand range to include all verses
                    start_verse_num = start_ref['verse']
                    end_verse_num = end_ref['verse']
                    
                    # Ensure start is less than end
                    if start_verse_num > end_verse_num:
                        start_verse_num, end_verse_num = end_verse_num, start_verse_num
                    
                    # Generate all verses in range
                    for verse_num in range(start_verse_num, end_verse_num + 1):
                        references.append({
                            "book": start_ref['book'],
                            "chapter": start_ref['chapter'],
                            "verse": verse_num
                        })
                else:
                    # Different book/chapter, add both as separate references
                    references.append(start_ref)
                    references.append(end_ref)
            else:
                # Fallback: try to parse each part separately
                for range_verse in range_parts:
                    ref = parse_single_verse(range_verse.strip())
                    if ref:
                        references.append(ref)
        else:
            # Multiple dashes, parse each part separately
            for range_verse in range_parts:
                ref = parse_single_verse(range_verse.strip())
                if ref:
                    references.append(ref)
    else:
        # Single verse
        ref = parse_single_verse(verse_ref)
        if ref:
            references.append(ref)
    
    return references

def parse_single_verse(verse_ref):
    """Parse single verse reference like 'Gen.1.1'"""
    parts = verse_ref.split('.')
    if len(parts) >= 3:
        book_abbr = parts[0]
        chapter = int(parts[1])
        verse = int(parts[2])
        
        # Convert to Telugu book name
        telugu_book = convert_english_to_telugu_book_name(book_abbr)
        
        return {
            "book": telugu_book,
            "chapter": chapter,
            "verse": verse
        }
    return None

def convert_original_format_to_json(input_file, output_file):
    """
    Convert the original cross references format to JSON
    Format: "Gen.1.1 Prov.16.4 56" or "Gen.1.1 John.1.1-John.1.3 340"
    """
    print("Converting original format to JSON...")
    
    cross_refs = defaultdict(list)
    range_count = 0
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Skip header line
        data_lines = lines[1:] if lines else []
        
        for line_num, line in enumerate(data_lines, 1):
            line = line.strip()
            if not line:
                continue
            
            # Parse line: "Gen.1.1 Prov.16.4 56" or "Gen.1.1 John.1.1-John.1.3 340"
            parts = line.split('\t')  # Split by tab
            if len(parts) >= 2:
                from_verse = parts[0]  # e.g., "Gen.1.1"
                to_verse = parts[1]    # e.g., "Prov.16.4" or "John.1.1-John.1.3"
                
                # Debug: Show verse ranges being processed
                if '-' in to_verse:
                    range_count += 1
                    if range_count <= 5:  # Show first 5 ranges
                        print(f"Processing range: {from_verse} -> {to_verse}")
                
                # Parse source verse
                source_refs = parse_verse_reference(from_verse)
                if source_refs:
                    source_ref = source_refs[0]  # Take first one as source
                    source_key = f"{source_ref['book']}|{source_ref['chapter']}|{source_ref['verse']}"
                    
                    # Parse target verses (can be multiple)
                    target_refs = parse_verse_reference(to_verse)
                    
                    # Debug: Show expanded references for ranges
                    if '-' in to_verse and range_count <= 5:
                        print(f"  Expanded to {len(target_refs)} references: {target_refs[:3]}...")
                    
                    # Add all target references to this source
                    for target_ref in target_refs:
                        cross_refs[source_key].append(target_ref)
        
        # Convert defaultdict to regular dict for JSON serialization
        result = dict(cross_refs)
        
        # Write to JSON file
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Original format conversion completed!")
        print(f"📁 Output file: {output_file}")
        print(f"📊 Total source verses: {len(result)}")
        print(f"🔗 Total references: {sum(len(refs) for refs in result.values())}")
        print(f"📈 Total verse ranges processed: {range_count}")
        
        # Show sample output
        print("\n📋 Sample JSON structure:")
        sample_key = list(result.keys())[0] if result else None
        if sample_key:
            print(f"Key: '{sample_key}'")
            print(f"Value: {json.dumps(result[sample_key][:3], indent=2, ensure_ascii=False)}")  # Show first 3 references
        
        return result
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def main():
    """Main function"""
    input_file_original = "app/src/main/assets/cross_references.txt"
    output_file_original = "app/src/main/assets/new_cross_references.json"
    
    print("🔄 Cross References to JSON Converter")
    print("=" * 50)
    
    # Convert original file to JSON with proper book names
    print("\n1️⃣ Converting original file to JSON with Telugu book names...")
    convert_original_format_to_json(input_file_original, output_file_original)
    
    print("\n✅ Conversion completed!")
    print(f"📁 JSON file: {output_file_original}")
    print("📋 JSON Structure:")
    print("  Key: 'TeluguBookName|Chapter|Verse'")
    print("  Value: [{'book': 'TeluguBookName', 'chapter': number, 'verse': number}, ...]")

if __name__ == "__main__":
    main()
