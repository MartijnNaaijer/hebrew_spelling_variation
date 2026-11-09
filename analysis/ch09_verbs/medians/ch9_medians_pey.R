# Chapter 9 Table 9.73 (2026-11-04): pe-yod contrasts with the imperfect from pey2_M1 (stored with the perfect as reference).
suppressMessages(library(posterior))
d <- as_draws_df(readRDS('D:/brms_models_spelling/analysis_verbs/pey2_M1.rds'))
f2 <- function(x) formatC(x, format = 'f', digits = 2)
im <- d$b_vtimpf
L <- list('Intercept (imperfect)' = d$b_Intercept + im, imperative = d$b_vtimpv - im, infa = d$b_vtinfa - im,
          infc = d$b_vtinfc - im, participle = d$b_vtparticiple - im, perfect = -im, wayyiqtol = d$b_vtwayq - im)
for (n in names(L)) { x <- L[[n]]
  cat(sprintf('%-24s mean %6s | median %6s sd %5s [%6s, %6s] pd %s\n', n, f2(mean(x)), f2(median(x)), f2(sd(x)),
      f2(quantile(x, .025)), f2(quantile(x, .975)), f2(max(mean(x > 0), mean(x < 0))))) }
