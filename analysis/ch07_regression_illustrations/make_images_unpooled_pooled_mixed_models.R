library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(ggeffects)


MODEL_FOLDER <- 'C:/Users/geitb/Kopenhagen/KopenhagenResearch/monograph/chapters/NounsAdjectives/models_rstanarm'

EBH_BOOKS <- c("Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", 
               "Judges", "1_Samuel", "2_Samuel", "1_Kings", "2_Kings")
LBH_BOOKS <- c("Esther", "Daniel", "Ezra", "Nehemiah", "1_Chronicles", "2_Chronicles")

LAW_BOOKS <- c("Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy")

QSP_SCROLLS = c('2Q3', '4Q13', '4Q20', '2Q7', '4Q27', '1Q4', '2Q12', '4Q37', '4Q38', '4Q38a', '4Q40', '4Q53',
                '1Qisaa', '4Q57', '2Q13', '4Q78', '4Q80', '4Q82', '4Q128', '4Q129', '4Q134', '4Q135', '4Q136',
                '4Q137', '4Q138', '4Q139', '4Q140', '4Q141', '4Q142', '4Q143', '4Q144', '4Q158', '4Q364',
                '4Q365', '4Q96', '4Q111', '4Q109', '11Q5', '11Q6', '11Q7', '11Q8')
length(QSP_SCROLLS)

logit2prob <- function(logit){
  odds <- exp(logit)
  prob <- odds / (1 + odds)
  return(prob)
}

dat <- read.csv('C:/Users/geitb/Kopenhagen/KopenhagenResearch/scripts_research/hebrew_spelling_variation/data/nouns_adjectives.csv', sep='\t')
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

dat$neigh_vowel_letter <- as.factor(dat$neigh_vowel_letter)

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

mt <- dat %>% filter(scroll == 'MT')

#############################################################

variation_lex_type_list <- list()
for (lex_t in unique(mt$lex_type)) {
  lex_type_df <- mt %>% filter(lex_type == lex_t)
  lt_vowels <- unique(lex_type_df$has_vowel_letter)
  if (length(lt_vowels) > 1) {
    variation_lex_type_list[[lex_t]] <- lex_type_df
  }
}

mt_var <- do.call('rbind', variation_lex_type_list)
mt_var <- mt_var[order(mt_var$tf_id),]
head(mt_var)
levels(mt_var$type)
dim(mt_var)
str(mt_var)

mt_var <- droplevels(mt_var)

################################################################################

# Select books

mt_var_adapt <- mt_var |> filter(book %in% c('Genesis', 'Exodus', 'Jonah', 'Obadiah', 'Ruth'))
dim(mt_var_adapt)
table(mt_var$book)

##########################################################################

# Pooled model

formula_mt <- has_vowel_letter ~ 
  has_nme 


bayes_model_mt_var <- fit_brm_model(mt_var_adapt, 
                                    formula_mt,
                                    1000, 2000, 0.9)


summary(bayes_model_mt_var)

fixed_draws <- bayes_model_mt_var %>%
  spread_draws(b_Intercept, 
               b_has_nme1,
               
  )
head(fixed_draws)

intercept <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept, .width = c(.95, .66))
intercept$feature <- 'Intercept'

nme <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_has_nme1, .width = c(.95, .66))
nme$feature <- 'With Nominal Ending'

fixed_last_syll <- rbind(intercept, nme)
fixed_last_syll

fixed_last_syll$feature <- factor(fixed_last_syll$feature, levels = c( 'With Nominal Ending', 
                                                                       'Intercept'))


fixed_last_syll %>% 
  ggplot(aes(y = feature, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval() #+
# ggtitle('Log odds of having a vowel letter in nouns and adjectives in MT')


################################################################################

# Unpooled model

formula_mt <- has_vowel_letter ~ 
  has_nme*book2


bayes_model_mt_var <- fit_brm_model(mt_var_adapt, 
                                    formula_mt,
                                    1000, 2000, 0.9)

summary(bayes_model_mt_var)

fixed_draws <- bayes_model_mt_var %>%
  spread_draws(b_Intercept, b_has_nme1, 
               b_book2Genesis,  b_book2Jonah, b_book2Obadiah, b_book2Obadiah, b_book2Ruth,
               `b_has_nme1:book2Genesis`, `b_has_nme1:book2Jonah`, `b_has_nme1:book2Obadiah`, `b_has_nme1:book2Ruth`,
  )
head(fixed_draws)

intercept_exo <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept, .width = c(.95, .66))
intercept_exo$feature <- 'Intercept Exodus'

intercept_gen <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_book2Genesis, .width = c(.95, .66))
intercept_gen$feature <- 'Intercept Genesis'

intercept_jon <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_book2Jonah, .width = c(.95, .66))
intercept_jon$feature <- 'Intercept Jonah'

intercept_oba <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_book2Obadiah, .width = c(.95, .66))
intercept_oba$feature <- 'Intercept Obadiah'

intercept_rut <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_book2Ruth, .width = c(.95, .66))
intercept_rut$feature <- 'Intercept Ruth'

nme_exo <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_has_nme1, .width = c(.95, .66))
nme_exo$feature <- 'With Nominal Ending in Exodus'

nme_gen <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_has_nme1 + `b_has_nme1:book2Genesis`, .width = c(.95, .66))
nme_gen$feature <- 'With Nominal Ending in Genesis'

nme_jon <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_has_nme1 + `b_has_nme1:book2Jonah`, .width = c(.95, .66))
nme_jon$feature <- 'With Nominal Ending in Jonah'

nme_oba <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_has_nme1 + `b_has_nme1:book2Obadiah`, .width = c(.95, .66))
nme_oba$feature <- 'With Nominal Ending in Obadiah'

nme_rut <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_has_nme1 + `b_has_nme1:book2Ruth`, .width = c(.95, .66))
nme_rut$feature <- 'With Nominal Ending in Ruth'

fixed_last_syll <- rbind(intercept_gen, nme_gen,
                         intercept_exo, nme_exo,
                         intercept_oba, nme_oba,
                         intercept_jon, nme_jon,
                         intercept_rut, nme_rut
)
fixed_last_syll

fixed_last_syll$feature <- factor(fixed_last_syll$feature, levels = c( 'With Nominal Ending in Ruth', 
                                                                       'Intercept Ruth',
                                                                       'With Nominal Ending in Jonah', 
                                                                       'Intercept Jonah',
                                                                       'With Nominal Ending in Obadiah', 
                                                                       'Intercept Obadiah',
                                                                       'With Nominal Ending in Exodus', 
                                                                       'Intercept Exodus',
                                                                       'With Nominal Ending in Genesis', 
                                                                       'Intercept Genesis'))


fixed_last_syll %>% 
  ggplot(aes(y = feature, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval()

###############################################################################

# PArtly pooled model

formula_mt2 <- has_vowel_letter ~ 
  has_nme +
  (nme | book2)


bayes_model_mt_var2 <- fit_brm_model(mt_var_adapt, 
                                     formula_mt2,
                                     3000, 6000, 0.99)

summary(bayes_model_mt_var)

vars_model <- get_variables(bayes_model_mt_var2)
vars_model

fixed_draws <- bayes_model_mt_var2 %>%
  spread_draws(b_Intercept, b_has_nme1,
  )
fixed_draws

mt_draws_random <- bayes_model_mt_var2 %>%
  spread_draws(r_book2[book,term])
mt_draws_random
head(mt_draws_random)

data_wide <- spread(mt_draws_random, term, r_book2)
data_wide
head(data_Wide)

#intercept_last <-
random_intercept_book <- data_wide |>
  median_qi(condition_mean = Intercept, .width = c(.95, .66))

intercept_exo <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept, .width = c(.95, .66))
intercept_exo$feature <- 'Intercept Exodus'

intercept_gen <- fixed_draws %>%
  median_qi(condition_mean = b_Intercept + b_book2Genesis, .width = c(.95, .66))
intercept_gen$feature <- 'Intercept Genesis'



fixed_last_syll <- rbind(intercept_gen, nme_gen,
                         intercept_exo, nme_exo,
                         intercept_oba, nme_oba,
                         intercept_jon, nme_jon,
                         intercept_rut, nme_rut
)
fixed_last_syll

fixed_last_syll$feature <- factor(fixed_last_syll$feature, levels = c( 'With Nominal Ending in Ruth', 
                                                                       'Intercept Ruth',
                                                                       'With Nominal Ending in Jonah', 
                                                                       'Intercept Jonah',
                                                                       'With Nominal Ending in Obadiah', 
                                                                       'Intercept Obadiah',
                                                                       'With Nominal Ending in Exodus', 
                                                                       'Intercept Exodus',
                                                                       'With Nominal Ending in Genesis', 
                                                                       'Intercept Genesis'))


fixed_last_syll %>% 
  ggplot(aes(y = feature, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval()

