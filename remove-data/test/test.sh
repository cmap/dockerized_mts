#!/bin/sh

echo "number of ic50 lines in input"
cat ./reports_files_by_plot/lineage_enrichment/lineage_enrichment_volcano_data.csv | grep -c log2.ic50

echo "number of MEL lines in input"
cat ./reports_files_by_plot/lineage_enrichment/lineage_enrichment_volcano_data.csv | grep -c MEL

docker run -it -v $PWD:/data prismcmap/remove-data:develop --data_dir /data/reports_files_by_plot \
    --out /data/out/ --search_patterns "lineage_enrichment/*.csv" \
    --field "pert_dose" --value "log2.ic50" \
    --field "lin_abbreviation" --value "MEL" \
    -v -imf

echo "number of pert_dose=log2.ic50 lines in output"
cat ./out/lineage_enrichment/lineage_enrichment_volcano_data.csv | grep -c log2.ic50

echo "number of lin_abbreviation=MEL lines in output"
cat ./out/lineage_enrichment/lineage_enrichment_volcano_data.csv | grep -c MEL

rm -rf ./out