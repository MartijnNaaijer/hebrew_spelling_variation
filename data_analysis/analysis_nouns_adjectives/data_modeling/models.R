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

formula_dss_mt <- has_vowel_letter ~ 
                  has_prs*type*qsp + 
                  has_nme*type*qsp + 
                  has_prefix*type*qsp + 
                  (has_prs*type + has_nme*type + has_prefix*type | scroll/lex)
# Warning messages:
#1: Bulk Effective Samples Size (ESS) is too low, indicating posterior means and medians may be unreliable.
#Running the chains for more iterations may help. See
#https://mc-stan.org/misc/warnings.html#bulk-ess 
#2: Tail Effective Samples Size (ESS) is too low, indicating posterior variances and tail quantiles may be unreliable.
#Running the chains for more iterations may help. See
#https://mc-stan.org/misc/warnings.html#tail-ess


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
