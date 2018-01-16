./format_gex.pl Expression_drug_updated_10202017.txt > Expression_drug.new.txt
./format_gex.pl Expression_IFN_updated_10202017.txt > Expression_IFN.new.txt
 
# Genotyping_updated_10202017.txt and Expression_IFN_updated_10202017.txt have the same order of samples
# edit Genotyping.new.txt to leave only sample IDs

head -1 Expression_IFN.new.txt | tr "\t" "\n" | grep -P "US\." | tr "\n" "\t" | sed -e 's/\t$/\n/' > Genotyping.new.txt
tail -n+2 Genotyping_updated_10202017.txt >> Genotyping.new.txt
 
# Scripts to generate the HTML page, you may need to modify it to fit your own
# file format

# edit Interaction_terms.txt, 0 -> Unexposed, 1 -> Exposed
 
./make_gex_IFN.pl Expression_IFN.new.txt
 
./make_gex_drug.pl Expression_drug.new.txt

zip -r Lupus_eQTL.zip *.html *.pl package
