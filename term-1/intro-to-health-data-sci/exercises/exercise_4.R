# Exercise 4

df = read.table('exercises/data/cardiacdata.txt', header=TRUE, sep='\t')
head(df)

summary(df)

fsex = factor(df$sex,
              levels = c(1, 2),
              labels = c('Female', 'Male'))
# fsex
# head(df$smoking, n = 10)
fsmoking = factor(df$smoking,
              levels = c(1, 2, 3),
              labels = c('Current', 'Ex', 'Never'))
# fsmoking
df$fsex = fsex
df$fsmoking = fsmoking

summary(df)

# Q1
# hdlchol min at 0 -> impossible
# tryglyceride min at 0 -> impossible
# bmi max at 514.60 -> impossible

# Assign NA to impossible values
df
df[df$bmi == 514.6, 9] = NA
df[df$hdlchol == 0 & !is.na(df$hdlchol), 7] = NA
df[df$triglyceride == 0 & !is.na(df$triglyceride), 8] = NA

summary(df)
# Why is NA the right answer here, rather than deleting the whole patient record or guessing what the value should have been?
# > Data is still valid but just at that specific record the column value is invalid

# Q2
# Order by systolic pressure within each level of smoking status
ordered_cardiac = df[order(df$fsmoking, df$systolic),]
ordered_cardiac

# Q3
# mean age, systolic pressure, diastolic pressure and total cholesterol for each smoking category.
aggregate(
    df,
    list(df$fsmoking),
    FUN='mean'
)
# tchol, hdlchol, bmi -> invalid because of NA values assigned previously

# Q4
aggregate(
    df,
    list(df$fsmoking),
    mean,
    na.rm=TRUE
)
