# Exercise
# 2026-10-05

setwd('exercises')

# Q4
cardiac = read.table('data/cardiacdata.txt', header=TRUE, sep='\t', stringsAsFactors=TRUE)
str(cardiac)

cardiac$fsex = factor(cardiac$sex,
              levels = c(1, 2),
              labels = c('Female', 'Male'))
# fsex
# head(cardiac$smoking, n = 10)
cardiac$fsmoking = factor(cardiac$smoking,
              levels = c(1, 2, 3),
              labels = c('Current', 'Ex', 'Never'))

str(cardiac)


# Q5
table(cardiac$fsex, cardiac$fsmoking)
## Without useNA
##          Current Ex Never
##   Female      26 15    37
##   Male        24 37    17
# Current smoker is balanced, however ex-smoker and never smoked is conversely imbalanced

table(cardiac$fsex, cardiac$fsmoking, useNA='ifany')

## With useNA = 'ifany'
##         Current Ex Never <NA>
##  Female      26 15    37    0
##  Male        24 37    17    7
# Same as above but there are 7 missing data for male smokers

# Q6 - Scatter plot
par(mfrow=c(2,2)) # Creates a single figure with 2x2 room for 4 plots

dotchart(cardiac$bmi, main='BMI') # There's an extreme outlier with value > 500 (Impossible value)
dotchart(cardiac$systolic, main='Systolic')
dotchart(cardiac$tchol, main='Total cholesterol')
dotchart(cardiac$alcohol, main='Alcohol consumption')

# Q7 - Scatter plot after data cleaning
which(cardiac$bmi > 500)
cardiac[161,]

cardiac[which(cardiac$bmi > 500), c('bmi')] = NA
cardiac[cardiac$hdlchol == 0 & !is.na(cardiac$hdlchol), 7] = NA
cardiac[cardiac$triglyceride == 0 & !is.na(cardiac$triglyceride), 8] = NA

dotchart(cardiac$bmi, main='BMI') # No more extreme outlier
dotchart(cardiac$systolic, main='Systolic')
dotchart(cardiac$tchol, main='Total cholesterol')
dotchart(cardiac$alcohol, main='Alcohol consumption')


# Q8 - Histogram
par(mfrow=c(1,2))
hist(cardiac$bmi, main='BMI') # Light right skew
hist(cardiac$alcohol, main='Alcohol consumption') # Extreme right skew


# Q9 - Alcohol transformation
cardiac$alcohol_norm = sqrt(cardiac$alcohol)
hist(cardiac$alcohol, main='Alcohol consumption')
hist(cardiac$alcohol_norm, main='Alcohol consumption normalised') # Still right skew but not as extreme

# Q10 - Relationship via scatterplot
plot(x=cardiac$bmi, y=cardiac$systolic, main='bmi v systolic')
plot(x=cardiac$triglyceride, y=cardiac$hdlchol, main='triglyceride v hdl')


# Q11 - Boxplot
par(mfrow=c(1,1))
boxplot(
    cardiac$hdlchol ~ cardiac$fsmoking,
    xlab='Smoking Status',
    ylab='HDL Cholesterol',
    ann=TRUE
)


# Q12 - Violin plot
vioplot::vioplot(
    formula=cardiac$hdlchol ~ cardiac$fsmoking,
    use.cols=TRUE,
    xlab='Smoking Status',
    ylab='HDL Cholesterol',
    main='HDL cholesterol for every smoking status'
)


# Q13 - Pair plots
# Helper function to calculate correlation coefficient
panel.cor <- function(x, y, digits = 2, prefix = "", cex.cor, ...) {
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))

  # Calculate correlation (handling missing values safely)
  r <- cor(x, y, use = "pairwise.complete.obs")

  # Format the text display
  txt <- format(c(r, 0.123456789), digits = digits)[1]
  txt <- paste0(prefix, txt)

  # Scale font size dynamically based on the correlation strength
  if(missing(cex.cor)) cex.cor <- 0.8 / strwidth(txt)
  text(0.5, 0.5, txt, cex = cex.cor * (0.4 + 0.6 * abs(r)))
}

corr_vars = c('age', 'systolic', 'diastolic', 'tchol',
            'hdlchol', 'triglyceride', 'bmi')
pairs(
    cardiac[, corr_vars],
    upper.panel=NULL, # =panel.cor for the correlation coeff value
    pch=21,
    # bg = c("red", "green", "blue")
)
