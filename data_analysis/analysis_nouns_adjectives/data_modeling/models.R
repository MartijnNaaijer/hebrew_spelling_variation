library(brms)

# MT models

formula4 <- has_vowel_letter ~ 
            has_prs*type*law_phase + 
            has_nme*type*law_phase + 
            has_prefix*type*law_phase + 
            (has_pronominal_suffix + has_nme + has_prefix | book2)

formula5 <- has_vowel_letter ~ 
            has_pronominal_suffix*type*law_phase + 
            has_nme*type*law_phase + 
            has_prefix*type*law_phase + 
            (has_pronominal_suffix + has_nme + has_prefix | book2) +
            (has_pronominal_suffix + has_nme + has_prefix | lex_type)

formula6 <- has_vowel_letter ~ 
            has_pronominal_suffix*type*law_phase + 
            has_nme*type*law_phase + 
            has_prefix*type*law_phase + 
            (has_pronominal_suffix*type + has_nme*type + has_prefix*type | book2)

formula7 <- has_vowel_letter ~ 
            has_pronominal_suffix*type*law_phase + 
            has_nme*type*law_phase + 
            has_prefix*type*law_phase + 
            (has_pronominal_suffix*type + has_nme*type + has_prefix*type | book2/lex_type)

formula8 <- has_vowel_letter ~ 
            has_pronominal_suffix*type*law_phase + 
            has_nme*type*law_phase + 
            has_prefix*type*law_phase


fit_brm_model <- function(df, formula) {
  brm_model <- brm(formula = formula,
                             prior = set_prior("normal(0, 1)", class = "Intercept") +
                               set_prior("normal(0,1)", class = "b"),
                             data = df, 
                             family = bernoulli(link = "logit"),
                             warmup = 4000, 
                             iter = 8000, 
                             chains = 4, 
                             cores=4,
                             control = list(adapt_delta = 0.95),
                             seed = 123)
  
  return(brm_model)
}


save_model <- function(model, model_folder, model_name) {
  model_path <- file.path(model_folder, model_name)
  saveRDS(model, file = model_path)
}
