# Explains linear regression for chapter on Bayesian regression analysis

IMAGE_FOLDER <- 'C:/Users/geitb/Dropbox/monograph_orthography/images_ch7_regression'

set.seed(42)
height <- runif(n=100, min=140, max=200)
weight <- height / (2 + rnorm(100)/10)
plot(height, weight)  

lin.model <- lm(weight ~ height)
summary(lin.model)

dat <- data.frame(height, weight)
dat
library('ggplot2')

raw <- ggplot(dat, aes(height, weight)) +            
  geom_point() +
  labs(x = 'Height (cm)', y = 'Weight (kg)')
raw

ggsave(file.path(IMAGE_FOLDER, 'raw_data.png'))

# RAW PLUS LINEAR MODEL
raw +                                  
  stat_smooth(method = "lm", 
              formula = y ~ x, 
              geom = "smooth") +
  labs(x = 'Height (cm)', y = 'Weight (kg)')
ggsave(file.path(IMAGE_FOLDER, 'lin_model.png'))

# WEIGHT CATEGORIES, LOGISTIC REGRESSION
dat$heavy_weight <- ifelse(dat$weight > 90, 1, 0)

raw_categ <- ggplot(dat, aes(height, heavy_weight)) +            
  geom_point() +
  labs(x = 'Height', y = 'Weight')
raw_categ
ggsave(file.path(IMAGE_FOLDER, 'raw_categ_data.png'))

raw_categ +                                
  stat_smooth(method = "lm", 
              formula = y ~ x, 
              geom = "smooth") +
  labs(x = 'Height', y = 'Weight')
ggsave(file.path(IMAGE_FOLDER, 'raw_categ_lin_model.png'))

# Logistic plot
raw_categ +                                      
  stat_smooth(method = "glm",
              method.args = list(family = "binomial"),
              formula = y ~ x, 
              geom = "smooth") +
  labs(x = 'Height (cm)', y = 'Weight')
ggsave(file.path(IMAGE_FOLDER, 'raw_categ_log_model.png'))

# WEIGHT AND HEIGHT CATEGORIES
dat$is_tall <- ifelse(dat$height > 180, 1, 0) |> as.factor()
dat$heavy_weight <- dat$heavy_weight |> as.factor()

# MAKE TABLE OF CATEGORIES
table(dat$is_tall, dat$heavy_weight)

# fit model
categ_model <- glm(heavy_weight ~ is_tall, data=dat, family='binomial')
coefs <- summary(categ_model)$coefficients |> as.data.frame()
coefs$tallness <- c('Not tall', 'Tall')

summary(categ_model)
################################

pred_df <- data.frame(is_tall = c(0, 1))
pred_df$is_tall <- pred_df$is_tall |> as.factor()
preds <- predict(categ_model, newdata = pred_df, se.fit = TRUE)

pred_df$heavy_weight_logit <- preds$fit
pred_df$upper_logit <- preds$fit + 1.96 * preds$se.fit
pred_df$lower_logit <- preds$fit - 1.96 * preds$se.fit

pred_df$heavy_weight <- exp(preds$fit)/(1 + exp(preds$fit))
pred_df$upper <- exp(preds$fit + 1.96 * preds$se.fit)/
  (1 + exp(preds$fit + 1.96 * preds$se.fit))
pred_df$lower <- exp(preds$fit - 1.96 * preds$se.fit)/
  (1 + exp(preds$fit - 1.96 * preds$se.fit))
pred_df

ggplot(pred_df, aes(is_tall, heavy_weight)) +
  geom_errorbar(aes(ymin = lower, ymax = upper), 
                color = "black",
                linewidth = 1, 
                width = 0.1, 
                #alpha = 0.5
                ) +
  geom_point(size = 5) +
  scale_x_discrete('', labels=c('Not tall', 'Tall')) +
  ylab('Probability of high weight class')

ggsave(file.path(IMAGE_FOLDER, 'discrete_probabilities.png'))

ggplot(pred_df, aes(is_tall, heavy_weight_logit)) +
  geom_errorbar(aes(ymin = lower_logit, ymax = upper_logit), 
                color = "black",
                linewidth = 1, 
                width = 0.1, 
                #alpha = 0.5
  ) +
  geom_point(size = 5) +
  scale_x_discrete('', labels=c('Not tall', 'Tall')) +
  ylab('Logit')

ggsave(file.path(IMAGE_FOLDER, 'discrete_logits.png'))
