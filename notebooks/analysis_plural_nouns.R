list.files()
getwd()
file = '../notebooks/plural_verbs.csv'

dat = read.csv(file, sep='\t')

mosaicplot(table(dat$has_suffix, dat$verb_ends_on_w))

mosaicplot(table(dat$w_in_suffix, dat$verb_ends_on_w))
