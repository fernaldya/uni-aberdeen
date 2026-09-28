# Exercise 3

# Q5
df = read.table('data/cardiacdata.txt', header=TRUE, sep='\t')
df

# Q6
head(df, n=6)

names(df) # returns the vector of column names

str(df) # Returns the structure, size, dtypes, and value samples

# Q7
# Factor to encode categorical text vars
# Sex -> 1: Female, 2: Male
# Smoking -> 1: Current, 2: Ex smoker, 3: Never

head(df$sex, n=3)

fsex = factor(df$sex,
              levels = c(1, 2),
              labels = c('Female', 'Male'))
fsex

head(df$smoking, n = 10)
fsmoking = factor(df$smoking,
              levels = c(1, 2, 3),
              labels = c('Current', 'Ex', 'Never'))
fsmoking

df$fsex = fsex
df$fsmoking = fsmoking

str(df)

# Q8
# Summary
summary(df)
# Max BMI -> 514.60 => Not possible

# Q9a
cardiac_risk = df[, c('patno', 'sex', 'smoking', 'tchol')]
head(cardiac_risk, 5)

# Q9b
cardiac_risk_exc = df[-(1:10), (-1)]
head(cardiac_risk_exc)

# Q10
# 1. patients with a systolic blood pressure greater than 160 mmHg
df_10_1 = df[df$systolic > 160, ]
head(df_10_1)

# 2. male patients who have never smoked and whose diastolic pressure is greater than the median diastolic pressure (76 mmHg)
df_10_2 = df[df$fsmoking == 'Never' & median(df$diastolic), ]
head(df_10_2)

# 3. all patients who are not ex-smokers
df_10_3 = df[df$fsmoking != 'Ex', ]
df_10_3


# Q10
df_filter = df[df$systolic > 160 & df$tchol > mean(df$tchol), ]
df_filter
