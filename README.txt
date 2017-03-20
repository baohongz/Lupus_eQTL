# Genotyping_updated_03102017.txt and Expression_IFN_updated_03102017.txt have the same order of samples
head -1 Expression_IFN.new.txt > Genotyping.new.txt

# edit Genotyping.new.txt to leave only sample IDs

tail -n+2 Genotyping_updated_03102017.txt >> Genotyping.new.txt


# Scripts to generate the HTML page, you may need to modify it to fit your own
# file format

./make_gex_IFN.pl Expression_IFN.new.txt

./make_gex_drug.pl Expression_drug.new.txt
