#!/usr/bin/env Rscript
args = commandArgs(trailingOnly = TRUE)
ensembl_release <- args[1]
wd <- args[2]
print("esembl release: ", ensembl_release)
print("wd: ", wd)
library(tidyverse)
library(biomaRt)
library(httr)

setwd(wd)
getwd()

new_config <- httr::config(ssl_verifypeer = FALSE)
httr::set_config(new_config, override = FALSE)

url <- filter(listEnsemblArchives(), version == ensembl_release)$url
mart <- useMart(biomart = "ENSEMBL_MART_ENSEMBL",
                dataset = "mmusculus_gene_ensembl",
                host = url)

#view(listMarts())
#view(listDatasets(mart))
#view(listAttributes(mart))
#view(listFilters(mart))

martdf <- getBM(attributes = c("ensembl_gene_id", "ensembl_gene_id_version",
                            "external_gene_name", "chromosome_name", 
                            "description", "gene_biotype"), mart = mart)

tsvfile <- sprintf("EnsMm_grc39_%s_Length_GC.tsv", ensembl_release)

length_table <- read.table(
  tsvfile, header = F, quote = "", sep = "\t"
)

names(length_table) <- c(
  "gene_id", "tx_id", "eu_length", "eu_gc",
  "pl_length","pl_gc","is_principal"
)

print(paste("Rows in length table:", nrow(length_table)))

names(martdf) <- c(
  "gene_id", "gene_id_version", "SYMBOL",
  "SEQNAME", "DESCRIPTION", "GENEBIOTYPE"
)

martdf <- martdf %>%
  rowwise() %>%
  mutate(
    gene_id_version=gsub(paste0(gene_id,"."),"",gene_id_version)
  )

print(paste("Rows in meta table:", nrow(martdf)))

gene_annotations <- inner_join(
  length_table, martdf, by="gene_id"
)

print(paste("Rows in annotation table:", nrow(gene_annotations)))

print(head(gene_annotations))

write.csv(
  gene_annotations,
  file="Mouse_Gene_Annotations.csv"
)
