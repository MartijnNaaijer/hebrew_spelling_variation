library(tidyverse)

library(FactoMineR)

EBH_BOOKS <- c("Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", 
               "Judges", "1_Samuel", "2_Samuel", "1_Kings", "2_Kings")
LBH_BOOKS <- c("Esther", "Daniel", "Ezra", "Nehemiah", "1_Chronicles", "2_Chronicles")

LAW_BOOKS <- c("Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy")

QSP_SCROLLS = c('2Q3', '4Q13', '4Q20', '2Q7', '4Q27', '1Q4', '2Q12', '4Q37', '4Q38', '4Q38a', '4Q40', '4Q53',
                '1Qisaa', '4Q57', '2Q13', '4Q78', '4Q80', '4Q82', '4Q128', '4Q129', '4Q134', '4Q135', '4Q136',
                '4Q137', '4Q138', '4Q139', '4Q140', '4Q141', '4Q142', '4Q143', '4Q144', '4Q158', '4Q364',
                '4Q365', '4Q96', '4Q111', '4Q109', '11Q5', '11Q6', '11Q7', '11Q8')
length(QSP_SCROLLS)

data_folder <- 'C:/Users/geitb/Kopenhagen/KopenhagenResearch/scripts_research/hebrew_spelling_variation/data'
dat <- read.csv(file.path(data_folder, 'nouns_adjectives.csv'), sep='\t')
dim(dat)
head(dat)
str(dat)
unique(dat$book)

sum(is.na(dat$pattern))
sum(table(dat$pattern))

dat$has_suffix <- dat$has_prs | dat$has_nme

# has_prefix, has_prs, has_nme, lex, book, has_vowel_letter
dat$has_prefix <- as.factor(dat$has_prefix)
dat$has_prs <- as.factor(dat$has_prs)
dat$has_suffix <- as.factor(dat$has_suffix)
dat$has_nme <- as.factor(dat$has_nme)
dat$lex <- as.factor(dat$lex)
dat$book <- as.factor(dat$book)
dat$has_vowel_letter <- as.factor(dat$has_vowel_letter)

dat$type <- as.factor(dat$type)
dat$lex_type <- paste(dat$lex, dat$type, sep='_')
dat$lex_type <- as.factor(dat$lex_type)

dat$book2 <- dat$book %>% str_replace('1_', '') %>% str_replace('2_', '')
table(dat$book2)

dat$phase <- ifelse(dat$book %in% EBH_BOOKS, 'EBH', ifelse(dat$book %in% LBH_BOOKS, 'LBH', 'NO'))
dat$law_phase <- ifelse(dat$book %in% LAW_BOOKS, 0, ifelse(dat$book %in% EBH_BOOKS, 1, 
                                                           ifelse(dat$book %in% LBH_BOOKS, 2, 3)))
dat$law_phase <- as.factor(dat$law_phase)
dat$qsp <- ifelse(dat$scroll %in% QSP_SCROLLS, 1, 0)

# Make 2 scrolls of 1Qisaa
dat$scroll <- ifelse(dat$scroll == '1Qisaa' & dat$chapter < 34, '1QisaaI', 
                     ifelse(dat$scroll == '1Qisaa' & dat$chapter > 33, '1QisaaII', 
                            dat$scroll))
dat$scroll <- as.factor(dat$scroll)
str(dat)
dat$type
dat$type <- factor(dat$type, levels = c('last', 'first', 'single'))
levels(dat$type)

##################################################

select_variable_lex_types <- function(df) {
  variation_lex_type_list <- list()
  for (lex_t in unique(df$lex_type)) {
    lex_type_df <- df %>% filter(lex_type == lex_t)
    lt_vowels <- unique(lex_type_df$has_vowel_letter)
    if (length(lt_vowels) > 1) {
      variation_lex_type_list[[lex_t]] <- lex_type_df
    }
  }
  
  var_lex_type_df <- do.call('rbind', variation_lex_type_list)
  var_lex_type_df <- var_lex_type_df[order(var_lex_type_df$tf_id),]
  return(var_lex_type_df)
}

#########################################################################

# MT SP WHOLE PENTATEUCH
# SCROLL VS lex_type vowel_letter

mt_sp_pent <- dat |> 
  filter(scroll %in% c('MT', 'SP'))|> 
  filter(book %in% LAW_BOOKS)

mt_sp_pent_var <- select_variable_lex_types(mt_sp_pent)
mt_sp_pent_var$scr_book <- str_c(mt_sp_pent_var$scroll, mt_sp_pent_var$book, sep = '_')
mt_sp_pent_var$lex_typ_vow <- str_c(mt_sp_pent_var$lex_type, mt_sp_pent_var$has_vowel_letter, sep = '_')

mt_sp_pent_var <- droplevels(mt_sp_pent_var)
scroll_data <- as.data.frame.matrix(table(mt_sp_pent_var$scroll, mt_sp_pent_var$lex_typ_vow))


pca <- PCA(t(scroll_data))
barplot(pca$eig[,2])
plot(pca)
dimdesc(pca)
plotellipses(pca)

###########################################################################

# MT_SP_DSS

# SCROLL VS lex_type vowel_letter


pent <- dat |> 
  filter(book %in% LAW_BOOKS)

pent$subcorp <- ifelse(pent$scroll == 'MT', 'MT', 
                       ifelse(pent$scroll == 'SP', 'SP', 
                              'DSS'))

pent$subcorp2 <- ifelse(pent$scroll == 'MT', 'MT', 
                       ifelse(pent$scroll == 'SP', 'SP', 
                              ifelse(pent$qsp == 1, 'DSS_QSP',
                                     'DSS')))
head(pent)

pent_var<- select_variable_lex_types(pent)
pent_var$lex_typ_vow <- str_c(pent_var$lex_type, pent_var$has_vowel_letter, sep = '_')

pent_var <- droplevels(pent_var)

table(pent_var$subcorp2)

pent_scroll_data <- as.data.frame.matrix(table(pent_var$subcorp, pent_var$lex_typ_vow))
pent_scroll_data[1:5, 1:5]

pent_scroll_data <- sweep(pent_scroll_data,2,colSums(pent_scroll_data),`/`)
pca.pent <- PCA(t(pent_scroll_data))

head(pent_var)
pent_scroll_data2 <- as.data.frame.matrix(table(pent_var$subcorp2, pent_var$lex_typ_vow))
pent_scroll_data2 <- sweep(pent_scroll_data2,2,colSums(pent_scroll_data2),`/`)
pca.pent2 <- PCA(t(pent_scroll_data2))

plot(pca.pent2)
plotellipses(pca.pent2)

#########################################################################

# Factor analysis

pent_scroll_data3 <- as.data.frame.matrix(table(pent_var$scroll, pent_var$lex_typ_vow))
pent_scroll_data3 <- sweep(pent_scroll_data3,2,colSums(pent_scroll_data3),`/`)
pca.pent3 <- PCA(t(pent_scroll_data3))
fac_scr <- factanal(pent_scroll_data3, factors=3)

#######################################################################

# Scroll VS AFFIX_has_vowel_letter

head(pent_var)

pent_var$prs_vow <- str_c('prs', pent_var$type, pent_var$has_prs, pent_var$has_vowel_letter, sep='_')
pent_var$nme_vow <- str_c('nme', pent_var$type, pent_var$has_nme, pent_var$has_vowel_letter, sep='_')
pent_var$pref_vow <- str_c('pref', pent_var$type, pent_var$has_prefix, pent_var$has_vowel_letter, sep='_')

head(pent_var)

pref_pent <- pent_var[,c('subcorp2', 'pref_vow')]
colnames(pref_pent) <- c('subcorp2', 'var')
prs_pent <- pent_var[,c('subcorp2', 'prs_vow')]
colnames(prs_pent) <- c('subcorp2', 'var')
nme_pent <- pent_var[,c('subcorp2', 'nme_vow')]
colnames(nme_pent) <- c('subcorp2', 'var')

var_pent <- rbind(pref_pent, prs_pent, nme_pent)

table(var_pent$subcorp2, var_pent$var)

pent_subc <- as.data.frame.matrix(table(var_pent$subcorp2, var_pent$var))
pent_subc <- sweep(pent_subc,2,colSums(pent_subc),`/`)
pca.subc3 <- PCA(t(pent_subc))
plot(pca.subc3)


pent_subc <- as.data.frame.matrix(table(var_pent$subcorp2, var_pent$var))
pent_subc
pent_subc_mt_sp <- pent_subc[2:4,]
pent_subc_mt_sp <- sweep(pent_subc_mt_sp,2,colSums(pent_subc_mt_sp),`/`)
pca.subc3_mt_sp <- PCA(t(pent_subc_mt_sp))
plot(pca.subc3_mt_sp)

pent_subc_mt_sp

# contrast qsp and sp
pent_subc_qsp_sp <- pent_subc[c(1, 2,3, 4),]
pent_subc_qsp_sp <- sweep(pent_subc_qsp_sp,2,colSums(pent_subc_qsp_sp),`/`)
pca.subc3_qsp_sp <- PCA(t(pent_subc_qsp_sp))
plot(pca.subc3_qsp_sp)



#############################################################################

dim(pent_var)
head(pent_var)
ltv_df <- as.data.frame.matrix(table(pent_var$subcorp2, pent_var$lex_typ_vow))
ltv_df[1:5, 1:5]
ltv_df <- sweep(ltv_df,2,colSums(ltv_df),`/`)
pca.ltv <- PCA(t(ltv_df))
plot(pca.ltv)

