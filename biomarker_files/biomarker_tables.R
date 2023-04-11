# load libraries
library(tidyverse)
library(taigr)
library(readr)
library(magrittr)
library(celllinemapr)  # probably should remove dependency

# load the data (internal versions)
# make sure that you use PUBLIC ones (for data sharing and publication reasons)
# datasets that don't change run to run are labeled as stable in comment

# shRNA (stable I think)
shRNA <- load.from.taiga(data.name='demeter2-combined-dc9c',
                         data.version=19,
                         data.file='gene_means_proc')
# micro RNA (stable)
miRNA <- load.from.taiga(data.name='mirna-expression-2c5f',
                         data.version=3,
                         data.file='CCLE_miRNA_20180525')
# metabolomics (stable)
MET <- load.from.taiga(data.name='metabolomics-cd0c',
                       data.version=4,
                       data.file='CCLE_metabolomics_20190502')
# RPPA (proteomics, stable)
RPPA <- load.from.taiga(data.name='depmap-rppa-1b43', 
                        data.version=3,
                        data.file='CCLE_RPPA_20181003')
# damaging mutations
damMUT <- load.from.taiga(data.name='public-21q4-a0d6', 
                          data.version=8, 
                          data.file='CCLE_mutations_bool_damaging')
# hotspot mutations
hsMUT <- load.from.taiga(data.name='public-21q4-a0d6',
                         data.version=8,
                         data.file='CCLE_mutations_bool_hotspot')
# other mutations
otherMUT <- load.from.taiga(data.name='public-21q4-a0d6',
                            data.version=8,
                            data.file='CCLE_mutations_bool_nonconserving')
# lineages (extracted from sample_info file)
LIN <- load.from.taiga(data.name='public-21q4-a0d6',
                       data.version=8,
                       data.file='sample_info')
# CRISPR gene effect
XPR <- load.from.taiga(data.name='public-21q4-a0d6',
                       data.version=8,
                       data.file='Achilles_gene_effect')
# RNA expression
GE <- load.from.taiga(data.name='public-21q4-a0d6',
                      data.version=8,
                      data.file='CCLE_expression')
# copy number (not absolute)
CNA <- load.from.taiga(data.name='public-21q4-a0d6',
                       data.version=8,
                       data.file='CCLE_gene_cn')
# repurposing primary (stable)
REP <- load.from.taiga(data.name='primary-screen-e5c7',
                       data.version=11,
                       data.file='primary-replicate-collapsed-logfold-change')
# repurposing primary metadata (stable)
rep_info <- load.from.taiga(data.name='primary-screen-e5c7',
                            data.version=11,
                            data.file='primary-replicate-collapsed-treatment-info')
# proteomics (mass spec, stable I think)
PROT <- load.from.taiga(data.name='total-proteome--5c50',
                        data.version=2,
                        data.file='normalized_protein_abundance')


# PRISM cell lines (taken from a recent screen)
cell_lines <- data.table::fread("~/Desktop/Old_MTS/MTS017_final/SSMD_TABLE.csv") %>%
  dplyr::distinct(ccle_name) %>%
  dplyr::mutate(broad_id = celllinemapr::ccle.to.arxspan(ccle_name, ignore.problems = T, check.unique.mapping = F)) %>%
  dplyr::filter(!is.na(broad_id))  # need arxspan to join

# for each table:
# 1) rename columns (add feature abbreviation to front)
# 2) rename rows by joining with PRISM cell table by arxspan (to get ccle_name)

# shRNA
shRNA <- t(shRNA)  # transpose
colnames(shRNA) <- paste("shRNA", word(colnames(shRNA), 1, sep = " "), sep = "_")
shRNA <- as_tibble(shRNA, rownames = "broad_id", .name_repair = make.names) %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct() %>%
  column_to_rownames("ccle_name")

# miRNA
colnames(miRNA) <- paste("miRNA", colnames(miRNA), sep = "_")
miRNA <- as_tibble(miRNA, rownames = "broad_id") %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct() %>%
  column_to_rownames("ccle_name")

# metabolomics
colnames(MET) <- paste("MET", colnames(MET), sep = "_")
MET <- as_tibble(MET, rownames = "broad_id") %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct() %>%
  column_to_rownames("ccle_name")

# protein expression
colnames(RPPA) <- paste("RPPA", colnames(RPPA), sep = "_")
RPPA <- as_tibble(RPPA, rownames = "broad_id") %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct() %>%
  column_to_rownames("ccle_name")

# lineage
LIN %<>% 
  dplyr::rename(ccle_name = CCLE_Name, depmap_id = DepMap_ID) %>%
  dplyr::filter(!grepl("MERGED", ccle_name))  # remove merged lines

# lineage table (write to long form)
lineages <- LIN %>%
  dplyr::distinct(depmap_id, ccle_name, lineage, lineage_subtype) %>%
  dplyr::filter(lineage != "unknown")  # only keep known values
all_annotations <- dplyr::union(lineages$lineage, lineages$lineage_subtype)

# make abbreviations and add to long table
abbreviations <- abbreviate(stringr::str_replace_all(all_annotations,
                                                     "[[:punct:]]", " "),
                            minlength = 4, strict = F,
                            method = "both.sides") %>%
  toupper()
names(abbreviations) <- all_annotations
lineages$lin_abbreviation <- abbreviations[lineages$lineage]
lineages$lin_sub_abbreviation <- abbreviations[lineages$lineage_subtype]
write.csv(lineages, "./lineages.csv")  # write abbreviations file

# create matrix with lineage, subtype, and sub-subtype (one hot encoded)
lin <- LIN %>% dplyr::distinct(ccle_name, lineage) %>%
  dplyr::filter(lineage != "")
sub <- LIN %>% dplyr::distinct(ccle_name, lineage_subtype) %>%
  dplyr::rename(lineage = lineage_subtype) %>%
  dplyr::filter(lineage != "")
sub2 <- LIN %>% dplyr::distinct(ccle_name, lineage_sub_subtype) %>%
  dplyr::rename(lineage = lineage_sub_subtype) %>%
  dplyr::filter(lineage != "")
LIN_table <- dplyr::bind_rows(lin, sub, sub2) %>%
  dplyr::distinct() %>%
  dplyr::mutate(from = 1)
LIN <- reshape2::acast(LIN_table, ccle_name ~ lineage,
                       value.var = "from", fill = 0)
colnames(LIN) <- paste("LIN", colnames(LIN), sep = "_")

# gene expression (RNA)
colnames(GE) <- paste("GE", word(colnames(GE), 1, sep = " "), sep = "_")
GE <- as_tibble(GE, rownames = "broad_id", .name_repair = make.names) %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct() %>%
  column_to_rownames("ccle_name")

# gene effect (CRISPR)
colnames(XPR) <- paste("XPR", word(colnames(XPR), 1, sep = " "), sep = "_")
XPR <- as_tibble(XPR, rownames = "broad_id", .name_repair = make.names) %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct() %>%
  column_to_rownames("ccle_name")

# copy number
colnames(CNA) <- paste("CNA", word(colnames(CNA), 1, sep = " "), sep = "_")
CNA <- as_tibble(CNA, rownames = "broad_id") %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct() %>%
  column_to_rownames("ccle_name")

# mutations (damaging, hotspot, other)
colnames(damMUT) <- paste("MUT_dam", word(colnames(damMUT), 1, sep = " "), sep = "_")
damMUT <- as_tibble(damMUT, rownames = "broad_id", .name_repair = make.names) %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct()
colnames(hsMUT) <- paste("MUT_hs", word(colnames(hsMUT), 1, sep = " "), sep = "_")
hsMUT <- as_tibble(hsMUT, rownames = "broad_id", .name_repair = make.names) %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct()
colnames(otherMUT) <- paste("MUT_other", word(colnames(otherMUT), 1, sep = " "), sep = "_")
otherMUT <- as_tibble(otherMUT, rownames = "broad_id", .name_repair = make.names) %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct()
MUT <- dplyr::inner_join(damMUT, hsMUT) %>%
  dplyr::inner_join(otherMUT) %>%
  column_to_rownames("ccle_name")

# repurposing
rep_info %<>%
  dplyr::select(column_name, dose, name, screen_id) %>%
  dplyr::filter(column_name %in% colnames(REP))
colnames(REP) <- paste("REP", colnames(REP), sep = "_")
REP <- as_tibble(REP, rownames = "broad_id") %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct() %>%
  column_to_rownames("ccle_name")

# total proteome
colnames(PROT) <- paste("PROT", word(colnames(PROT), 1, sep = " "), sep = "_")
PROT <- as_tibble(PROT, rownames = "broad_id",
                  .name_repair = function(x) make.names(x, unique = T)) %>%
  dplyr::distinct() %>%
  dplyr::inner_join(cell_lines) %>%
  dplyr::select(-broad_id) %>%
  dplyr::distinct() %>%
  column_to_rownames("ccle_name")

# filter out by variance > 0 (can alter threshold)
MUT <- MUT[, apply(MUT, 2, function(x) var(x, na.rm = TRUE)) > 0]
GE <- GE[, apply(GE, 2, function(x) var(x, na.rm = TRUE)) > 0]
shRNA <- shRNA[, apply(shRNA, 2, function(x) var(x, na.rm = TRUE)) > 0]
CNA <- CNA[, apply(CNA, 2, function(x) var(x, na.rm = TRUE)) > 0]
XPR <- XPR[, apply(XPR, 2, function(x) var(x, na.rm = TRUE)) > 0]
LIN <- LIN[, apply(LIN, 2, function(x) var(x, na.rm = TRUE)) > 0]
miRNA <- miRNA[, apply(miRNA, 2, function(x) var(x, na.rm = TRUE)) > 0]
RPPA <- RPPA[, apply(RPPA, 2, function(x) var(x, na.rm = TRUE)) > 0]
MET <- MET[, apply(MET, 2, function(x) var(x, na.rm = TRUE)) > 0]
PROT <- PROT[, apply(PROT, 2, function(x) var(x, na.rm = TRUE)) > 0]

# write files
write.csv(shRNA, "./data/shrna.csv")
write.csv(CNA, "./data/cna.csv")
write.csv(MUT, "./data/mut.csv")
write.csv(GE, "./data/ge.csv")
write.csv(LIN, "./data/lin.csv")
write.csv(MET, "./data/met.csv")
write.csv(miRNA, "./data/mirna.csv")
write.csv(XPR, "./data/xpr.csv")
write.csv(RPPA, "./data/rppa.csv")
write.csv(REP, "./data/rep.csv")
write.csv(rep_info, "./data/rep_info.csv")
write.csv(PROT, "./data/prot.csv")

# make combined tables for multivariate analyses (only keeps complete rows)

# ccle model = GE + LIN + MUT + CNA
X.ccle <- GE %>% rownames_to_column(var = "ccle_name") %>%
  dplyr::inner_join(as_tibble(LIN, rownames = "ccle_name")) %>%
  dplyr::inner_join(MUT %>% rownames_to_column(var = "ccle_name")) %>%
  dplyr::inner_join(CNA %>% rownames_to_column(var = "ccle_name")) %>%
  column_to_rownames("ccle_name")

# all model = ccle + XPR + RPPA + miRNA + MET
X.all <- X.ccle %>% rownames_to_column(var = "ccle_name") %>%
  dplyr::inner_join(XPR %>% rownames_to_column(var = "ccle_name")) %>%
  dplyr::inner_join(RPPA %>% rownames_to_column(var = "ccle_name")) %>%
  dplyr::inner_join(miRNA %>% rownames_to_column(var = "ccle_name")) %>%
  dplyr::inner_join(MET %>% rownames_to_column(var = "ccle_name")) %>%
  column_to_rownames("ccle_name")

# remove any columns with NAs (ranger requirement)
X.ccle <- X.ccle[, apply(X.ccle, 2, function(x) !any(is.na(x)))]
X.all <- X.all[, apply(X.all, 2, function(x) !any(is.na(x)))]

# write tables
write.csv(X.all, "./data/x-all.csv")
write.csv(X.ccle, "./data/x-ccle.csv")

# run PCA on lineage table (for use as confounder)
lin_PCs <- gmodels::fast.prcomp(LIN)
lin_PCs <- LIN %*% lin_PCs$rotation[, lin_PCs$sdev  > 0.2]
write.csv(lin_PCs, "./data/linPCA.csv")

# make long form mutation table (for reports)
mutations <- MUT %>%
  rownames_to_column("ccle_name") %>%
  reshape2::melt(id.vars = "ccle_name",
                 variable.name = "mutation",
                 value.name = "is_mutant") %>%
  dplyr::filter(is_mutant > 0) %>%
  dplyr::select(-is_mutant) %>%
  dplyr::mutate(mutation = word(mutation, 2, -1, sep = "_"))
write.csv(mutations, "./mutations.csv")
