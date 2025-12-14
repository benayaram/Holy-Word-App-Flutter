package com.holywordapp;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CrossReferenceManager {
    private static CrossReferenceManager instance;
    private Map<String, List<CrossReference>> crossReferencesMap;

    private CrossReferenceManager() {
        crossReferencesMap = new HashMap<>();
        initializeCrossReferences();
    }

    public static CrossReferenceManager getInstance() {
        if (instance == null) {
            instance = new CrossReferenceManager();
        }
        return instance;
    }

    public List<CrossReference> getCrossReferences(String book, int chapter, int verse) {
        String key = book + "_" + chapter + "_" + verse;
        return crossReferencesMap.getOrDefault(key, new ArrayList<>());
    }

    public List<CrossReference> getCrossReferencesForChapter(String book, int chapter) {
        List<CrossReference> chapterRefs = new ArrayList<>();
        for (int verse = 1; verse <= 50; verse++) { // Assuming max 50 verses per chapter
            String key = book + "_" + chapter + "_" + verse;
            List<CrossReference> verseRefs = crossReferencesMap.get(key);
            if (verseRefs != null) {
                chapterRefs.addAll(verseRefs);
            }
        }
        return chapterRefs;
    }

    public void updateCrossReferences(List<CrossReference> newCrossReferences) {
        // Clear existing cross references
        crossReferencesMap.clear();
        
        // Add new cross references
        for (CrossReference crossRef : newCrossReferences) {
            String key = crossRef.getSourceBook() + "_" + crossRef.getSourceChapter() + "_" + crossRef.getSourceVerse();
            crossReferencesMap.put(key, List.of(crossRef));
        }
    }

    private void initializeCrossReferences() {
        // Genesis 1:1 - Creation
        CrossReference gen1_1 = new CrossReference("ఆదికాండము", 1, 1, "ప్రారంభమందు దేవుడు ఆకాశమును భూమిని సృష్టించెను");
        gen1_1.addReference("యోహాను", 1, 1, "ప్రారంభమందు వాక్యము ఉండెను", "parallel");
        gen1_1.addReference("కీర్తనలు", 33, 6, "యెహోవా వాక్యముచేత ఆకాశములు సృజింపబడెను", "quotation");
        gen1_1.addReference("కీర్తనలు", 102, 25, "నీవు పూర్వకాలమందు భూమి స్థాపించితివి", "theme");
        crossReferencesMap.put("ఆదికాండము_1_1", List.of(gen1_1));

        // Genesis 1:26 - Man in God's image
        CrossReference gen1_26 = new CrossReference("ఆదికాండము", 1, 26, "దేవుడు మనవంటి మనుష్యులను చేయుదము");
        gen1_26.addReference("యాకోబు", 3, 9, "దేవుని సారూప్యముగా సృష్టింపబడిన మనుష్యులను", "quotation");
        gen1_26.addReference("1 కొరింథీయులకు", 11, 7, "దేవుని ప్రతిమగాను మహిమగాను ఉన్నవాడు", "allusion");
        crossReferencesMap.put("ఆదికాండము_1_26", List.of(gen1_26));

        // Genesis 3:15 - First Gospel
        CrossReference gen3_15 = new CrossReference("ఆదికాండము", 3, 15, "ఆమె సంతానమును నీ తలను నలగగొట్టును");
        gen3_15.addReference("గలతీయులకు", 4, 4, "స్త్రీ సంతానమైన క్రీస్తు", "fulfillment");
        gen3_15.addReference("రోమీయులకు", 16, 20, "శీఘ్రముగా సాతానును మీ కింద చితికగొట్టును", "fulfillment");
        crossReferencesMap.put("ఆదికాండము_3_15", List.of(gen3_15));

        // Genesis 12:3 - Abrahamic Covenant
        CrossReference gen12_3 = new CrossReference("ఆదికాండము", 12, 3, "నీవు దీవెనవాడవు");
        gen12_3.addReference("గలతీయులకు", 3, 8, "అబ్రాహామునందు దీవెనలు పొందెదరు", "fulfillment");
        gen12_3.addReference("లూకా", 1, 55, "అబ్రాహాము సంతానమునకు", "quotation");
        crossReferencesMap.put("ఆదికాండము_12_3", List.of(gen12_3));

        // Exodus 3:14 - I AM
        CrossReference exo3_14 = new CrossReference("నిర్గమకాండము", 3, 14, "నేను ఉన్నవాడనై ఉన్నవాడను");
        exo3_14.addReference("యోహాను", 8, 58, "నేను ఉన్నవాడనై ఉన్నవాడను", "quotation");
        exo3_14.addReference("యోహాను", 18, 6, "నేను ఉన్నవాడనై ఉన్నవాడను", "quotation");
        crossReferencesMap.put("నిర్గమకాండము_3_14", List.of(exo3_14));

        // Psalms 22:1 - My God, My God
        CrossReference psa22_1 = new CrossReference("కీర్తనల గ్రంథము", 22, 1, "నా దేవా, నా దేవా, నన్ను ఎందుకు విడిచితివి");
        psa22_1.addReference("మత్తయి", 27, 46, "నా దేవా, నా దేవా, నన్ను ఎందుకు విడిచితివి", "quotation");
        psa22_1.addReference("మార్కు", 15, 34, "నా దేవా, నా దేవా, నన్ను ఎందుకు విడిచితివి", "quotation");
        crossReferencesMap.put("కీర్తనల గ్రంథము_22_1", List.of(psa22_1));

        // Psalms 22:18 - Casting lots
        CrossReference psa22_18 = new CrossReference("కీర్తనల గ్రంథము", 22, 18, "వారు నా వస్త్రములను వారిలో పంచుకొని");
        psa22_18.addReference("యోహాను", 19, 24, "వారు నా వస్త్రములను వారిలో పంచుకొని", "fulfillment");
        crossReferencesMap.put("కీర్తనల గ్రంథము_22_18", List.of(psa22_18));

        // Isaiah 7:14 - Virgin Birth
        CrossReference isa7_14 = new CrossReference("యెషయా గ్రంథము", 7, 14, "కన్య గర్భవతియై కుమారుని కనును");
        isa7_14.addReference("మత్తయి", 1, 23, "కన్య గర్భవతియై కుమారుని కనును", "fulfillment");
        isa7_14.addReference("లూకా", 1, 31, "మరియా గర్భవతియై కుమారుని కనును", "fulfillment");
        crossReferencesMap.put("యెషయా గ్రంథము_7_14", List.of(isa7_14));

        // Isaiah 9:6 - Wonderful Counselor
        CrossReference isa9_6 = new CrossReference("యెషయా గ్రంథము", 9, 6, "అద్భుత సలహాకుడు, బలవంతుడైన దేవుడు");
        isa9_6.addReference("లూకా", 2, 11, "దావీదు పట్టణమందు మీకొరకు క్రీస్తు ప్రభువు జన్మించెను", "fulfillment");
        crossReferencesMap.put("యెషయా గ్రంథము_9_6", List.of(isa9_6));

        // Isaiah 53:3 - Suffering Servant
        CrossReference isa53_3 = new CrossReference("యెషయా గ్రంథము", 53, 3, "అతడు తిరస్కరింపబడి మనుష్యులచే నిరాకరింపబడెను");
        isa53_3.addReference("యోహాను", 1, 11, "తనవారు అతనిని స్వీకరించలేదు", "fulfillment");
        isa53_3.addReference("మత్తయి", 27, 39, "తిరస్కరించుచు తలలు ఊపిరి", "fulfillment");
        crossReferencesMap.put("యెషయా గ్రంథము_53_3", List.of(isa53_3));

        // Isaiah 53:5 - Wounded for our transgressions
        CrossReference isa53_5 = new CrossReference("యెషయా గ్రంథము", 53, 5, "మన అపరాధములనిమిత్తము అతడు గాయపడెను");
        isa53_5.addReference("1 పేతురు", 2, 24, "మన పాపములను తన శరీరముమీద ధరించెను", "fulfillment");
        crossReferencesMap.put("యెషయా గ్రంథము_53_5", List.of(isa53_5));

        // Jeremiah 31:31 - New Covenant
        CrossReference jer31_31 = new CrossReference("యిర్మీయా", 31, 31, "నేను ఇశ్రాయేలు వంశముతోను యూదా వంశముతోను క్రొత్త నిబంధన చేసెదను");
        jer31_31.addReference("లూకా", 22, 20, "ఈ పాత్ర నా రక్తముతో క్రొత్త నిబంధన", "fulfillment");
        jer31_31.addReference("హెబ్రీయులకు", 8, 8, "క్రొత్త నిబంధన చేయుదును", "quotation");
        crossReferencesMap.put("యిర్మీయా_31_31", List.of(jer31_31));

        // Daniel 9:25 - Messiah Prince
        CrossReference dan9_25 = new CrossReference("దానియేలు", 9, 25, "మెస్సీయ ప్రభువు వచ్చెదవు");
        dan9_25.addReference("లూకా", 19, 38, "ప్రభువు నామమున వచ్చు రాజు", "fulfillment");
        crossReferencesMap.put("దానియేలు_9_25", List.of(dan9_25));

        // Micah 5:2 - Bethlehem
        CrossReference mic5_2 = new CrossReference("మీకా", 5, 2, "బేత్లెహేములో నీకొరకు ఒకడు నాకు బయలుదేరును");
        mic5_2.addReference("మత్తయి", 2, 6, "బేత్లెహేములో నీకొరకు ఒకడు నాకు బయలుదేరును", "fulfillment");
        crossReferencesMap.put("మీకా_5_2", List.of(mic5_2));

        // Zechariah 9:9 - Riding on donkey
        CrossReference zec9_9 = new CrossReference("జెకర్యా", 9, 9, "నీవు గాడిదపై ఎక్కి వచ్చెదవు");
        zec9_9.addReference("మత్తయి", 21, 5, "నీవు గాడిదపై ఎక్కి వచ్చెదవు", "fulfillment");
        zec9_9.addReference("యోహాను", 12, 15, "గాడిదపై ఎక్కి వచ్చెదవు", "fulfillment");
        crossReferencesMap.put("జెకర్యా_9_9", List.of(zec9_9));

        // Malachi 3:1 - Messenger
        CrossReference mal3_1 = new CrossReference("మలాకీ", 3, 1, "నా దూతను పంపెదను");
        mal3_1.addReference("మత్తయి", 11, 10, "నా దూతను పంపెదను", "quotation");
        mal3_1.addReference("మార్కు", 1, 2, "నా దూతను పంపెదను", "quotation");
        crossReferencesMap.put("మలాకీ_3_1", List.of(mal3_1));

        // Matthew 1:23 - Immanuel
        CrossReference mat1_23 = new CrossReference("మత్తయి సువార్త", 1, 23, "అతని పేరు ఇమ్మానువేలు");
        mat1_23.addReference("యెషయా గ్రంథము", 7, 14, "అతని పేరు ఇమ్మానువేలు", "prophecy");
        crossReferencesMap.put("మత్తయి సువార్త_1_23", List.of(mat1_23));

        // Matthew 2:6 - Bethlehem
        CrossReference mat2_6 = new CrossReference("మత్తయి సువార్త", 2, 6, "బేత్లెహేములో నీకొరకు ఒకడు నాకు బయలుదేరును");
        mat2_6.addReference("మీకా", 5, 2, "బేత్లెహేములో నీకొరకు ఒకడు నాకు బయలుదేరును", "prophecy");
        crossReferencesMap.put("మత్తయి సువార్త_2_6", List.of(mat2_6));

        // John 1:1 - In the beginning
        CrossReference joh1_1 = new CrossReference("యోహాను సువార్త", 1, 1, "ప్రారంభమందు వాక్యము ఉండెను");
        joh1_1.addReference("ఆదికాండము", 1, 1, "ప్రారంభమందు దేవుడు ఆకాశమును భూమిని సృష్టించెను", "parallel");
        crossReferencesMap.put("యోహాను సువార్త_1_1", List.of(joh1_1));

        // John 3:16 - For God so loved
        CrossReference joh3_16 = new CrossReference("యోహాను సువార్త", 3, 16, "దేవుడు లోకమును ఎంతో ప్రేమించెను");
        joh3_16.addReference("1 యోహాను", 4, 9, "దేవుడు తన ఏకైక కుమారుని లోకములో పంపెను", "theme");
        crossReferencesMap.put("యోహాను సువార్త_3_16", List.of(joh3_16));

        // Romans 3:23 - All have sinned
        CrossReference rom3_23 = new CrossReference("రోమీయులకు", 3, 23, "అందరును పాపము చేసి దేవుని మహిమకు తప్పిపోయిరి");
        rom3_23.addReference("1 యోహాను", 1, 8, "మనకు పాపము లేదని చెప్పుకొంటే", "theme");
        crossReferencesMap.put("రోమీయులకు_3_23", List.of(rom3_23));

        // Romans 6:23 - Wages of sin
        CrossReference rom6_23 = new CrossReference("రోమీయులకు", 6, 23, "పాపమునకు వేతనము మరణము");
        rom6_23.addReference("యాకోబు", 1, 15, "పాపము పరిపక్వమై మరణమును కనుక్కొనును", "theme");
        crossReferencesMap.put("రోమీయులకు_6_23", List.of(rom6_23));

        // 1 Corinthians 15:3-4 - Gospel
        CrossReference cor15_3 = new CrossReference("1 కొరింథీయులకు", 15, 3, "క్రీస్తు మన పాపములనిమిత్తము మరణించెను");
        cor15_3.addReference("యెషయా గ్రంథము", 53, 5, "మన అపరాధములనిమిత్తము అతడు గాయపడెను", "prophecy");
        cor15_3.addReference("యోనా", 1, 17, "మూడు రాత్రులు మూడు పగళ్లు", "allusion");
        crossReferencesMap.put("1 కొరింథీయులకు_15_3", List.of(cor15_3));

        // Revelation 21:1 - New heaven and earth
        CrossReference rev21_1 = new CrossReference("ప్రకటన గ్రంథము", 21, 1, "క్రొత్త ఆకాశమును క్రొత్త భూమిని చూచితిని");
        rev21_1.addReference("యెషయా గ్రంథము", 65, 17, "క్రొత్త ఆకాశమును క్రొత్త భూమిని సృష్టించెదను", "prophecy");
        rev21_1.addReference("2 పేతురు", 3, 13, "నీతి నివసించు క్రొత్త ఆకాశములు", "theme");
        crossReferencesMap.put("ప్రకటన గ్రంథము_21_1", List.of(rev21_1));
    }
}
