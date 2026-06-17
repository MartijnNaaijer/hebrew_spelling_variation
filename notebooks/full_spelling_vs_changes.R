file = 'C:/Users/geitb/Kopenhagen/KopenhagenResearch/scripts_research/hebrew_spelling_variation/notebooks/change_df_infc_qal_triliteral.csv'

df = read.csv2(file)
df
df$larger_than_random_changes <- as.numeric(df$larger_than_random_changes)
df$fullness <- as.numeric(df$fullness)
str(df)
df
lm_changes <- lm(df$larger_than_random_changes ~ df$fullness)
summary(lm_changes)

plot(df$fullness, 
     df$larger_than_random_changes, 
     xlab='Fraction of fully spelled qal active participles', 
     ylab='The difference between the number of spelling changes in randomly formed sequences and the sequences of qal active participles in MT books')
abline(lm(df$larger_than_random_changes ~ df$fullness))
text(df$fullness, df$larger_than_random_changes, df$book, cex=1, pos=4, col="red")



df[df$larger_than_random_changes > 9750,]

9/34
