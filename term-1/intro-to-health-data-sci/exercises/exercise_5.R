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

# Q6
par(mfrow=c(2,2)) # Creates a single figure with 2x2 room for 4 plots
dotchart(cardiac$bmi, labels='BMI') # There's an outlier with value > 500
dotchart(cardiac$systolic, labels='Systolic')
dotchart(cardiac$tchol, labels='Total cholesterol')
dotchart(cardiac$alcohol, labels='Alcohol consumption')
