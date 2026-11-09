# Runner for an approved verb refit: sections 0-3 of
# analysis/ch09_verbs/<id>/analysis.R with ALLOW_FIT TRUE (in memory only;
# the script keeps FALSE). Stored fits and k-folds are reused, so a stopped
# run can be restarted. Writes tools/logs/<id>_refit_done.flag at the end.
# First used for ptcp_qal (prefix ptcp_d3_, approved 2026-11-04).
#   Rscript analysis/ch09_verbs/tools/run_verb_refit.R <id> > analysis/ch09_verbs/tools/logs/<id>_refit.log 2>&1
#   (from the repository root)
ID <- commandArgs(trailingOnly = TRUE)[1]
source('analysis/paths.R')
VERBS_DIR <- CH09_DIR
LOG_DIR <- file.path(CH09_DIR, 'tools', 'logs')
dir.create(LOG_DIR, showWarnings = FALSE)
flag <- file.path(LOG_DIR, paste0(ID, '_refit_done.flag')); unlink(flag)
stopifnot('Model folder not available' = dir.exists(file.path(MODEL_ROOT, 'analysis_verbs')))
txt <- readLines(file.path(VERBS_DIR, ID, 'analysis.R'), encoding = 'UTF-8')
txt <- txt[seq_len(grep('^# ==== 4. DATA VISUALISATION ====', txt) - 1)]
i <- grep('^ALLOW_FIT <- FALSE', txt); stopifnot(length(i) == 1)
txt[i] <- 'ALLOW_FIT <- TRUE'
exprs <- parse(text = txt, encoding = 'UTF-8')
tryCatch({
  cat('Start', ID, format(Sys.time()), '\n')
  for (e in exprs) {
    t0 <- Sys.time()
    v <- withVisible(eval(e, globalenv())); if (v$visible) print(v$value)
    if (as.numeric(difftime(Sys.time(), t0, units = 'mins')) > 1)
      cat(sprintf('[%s] done after %.1f min: %s\n', format(Sys.time()),
                  as.numeric(difftime(Sys.time(), t0, units = 'mins')),
                  substr(paste(deparse(e), collapse = ' '), 1, 80)))
  }
  cat('End', ID, format(Sys.time()), '\n')
}, finally = writeLines(format(Sys.time()), flag))
