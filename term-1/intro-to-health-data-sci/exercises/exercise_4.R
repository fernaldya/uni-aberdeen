# Exercise 4
setwd('exercises')

df = read.table('data/cardiacdata.txt', header=TRUE, sep='\t', stringsAsFactors=TRUE)
str(df)

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

str(df)

# Q1
# hdlchol min at 0 -> impossible
# tryglyceride min at 0 -> impossible
# bmi max at 514.60 -> impossible

# Assign NA to impossible values
df
df$bmi[df$bmi > 100] = NA
df$hdlchol[df$hdlchol == 0] = NA
df$triglyceride[df$triglyceride == 0] = NA

summary(df)
# Why is NA the right answer here, rather than deleting the whole patient record or guessing what the value should have been?
# > Data is still valid but just at that specific record the column value is invalid


# Q2
# Order by systolic pressure within each level of smoking status
ordered_cardiac = df[order(df$fsmoking, df$systolic), ]
ordered_cardiac
tail(ordered_cardiac) # Tail puts ordered set of NA values at the end


# Q3
# mean age, systolic pressure, diastolic pressure and total cholesterol for each smoking category.
aggregate(
    df[, c('age', 'sex', 'systolic', 'diastolic', 'tchol', 'hdlchol', 'triglyceride', 'bmi', 'alcohol')],
    list(df$fsmoking),
    FUN='mean',
    na.rm=TRUE
)
# tchol, hdlchol, bmi -> invalid because of NA values assigned previously
# na.rm -> no longer invalid


# Q4
agg_df_cols = c('age', 'diastolic', 'tchol')
## by smoking status
# Mean
aggregate(
    df[agg_df_cols],
    list(df$fsmoking),
    mean,
    na.rm=TRUE
)

# Count
aggregate(
    df[agg_df_cols],
    by=list(smoking=df$fsmoking),
    FUN=length
)

# Median
aggregate(
    df[agg_df_cols],
    by=list(df$fsmoking),
    median,
    na.rm=TRUE
)

## by smoking status & sex
aggregate(
    df[agg_df_cols],
    by=list(
        smoking=df$fsmoking,
        sex=df$fsex
    ),
    mean,
    na.rm=TRUE
)

# Count
aggregate(
    df[agg_df_cols],
    by=list(
        smoking=df$fsmoking,
        sex=df$fsex
    ),
    FUN=length
)

# Median
aggregate(
    df[agg_df_cols],
    by=list(
        smoking=df$fsmoking,
        sex=df$fsex
    ),
    FUN=median,
    na.rm=TRUE
)

# Q5
table(df$fsmoking)
table(df$fsmoking, df$fsex)
# table() method by default drops NA values


# Q6
summary(df$triglyceride)

log_triglyceride = log10(df$triglyceride)
log_triglyceride
summary(log_triglyceride)

print('dataframe')
mean(df$triglyceride, na.rm=TRUE)
median(df$triglyceride, na.rm=TRUE)

print('logarithmic scale triglyceride')
mean(log_triglyceride, na.rm=TRUE)
median(log_triglyceride, na.rm=TRUE)

print('diff')
mean_diff = mean(df$triglyceride, na.rm=TRUE) - mean(log_triglyceride, na.rm=TRUE)
median_diff = median(df$triglyceride, na.rm=TRUE) - median(log_triglyceride, na.rm=TRUE)
mean_diff
median_diff

summary(df$triglyceride) - summary(log_triglyceride)


## ---------------------------------------------------------------------------

# Q7
df_followup = read.table('data/cardiac_followup.txt', header=TRUE, sep='\t', stringsAsFactors=TRUE)
str(df_followup)
dim(df)
dim(df_followup)

cardiac_fu = merge(
    x=df, y=df_followup,
    by.x='patno',
    by.y='patno'
)
head(cardiac_fu)
dim(cardiac_fu)
# How many rows does the linked dataframe have, and can you explain why?
# > followup dataframe only has 108 rows that also exists in the original dataframe; 55 patients lost
# > By default merge performs an inner join (all=FALSE)


# Q8
cardiac_fu_all = merge(
    x=df, y=df_followup,
    by.x='patno',
    by.y='patno',
    all.x=TRUE
)
head(cardiac_fu_all)
dim(cardiac_fu_all)

sum(is.na(cardiac_fu_all$systolic10)) # Total missing data / NA ||| TRUE = 1; FALSE = 0
summary(cardiac_fu_all$systolic10) # verified 55 NAs


# Q9
admissions = read.table('data/cardiac_admissions.txt', header=TRUE, sep='\t', stringsAsFactors=TRUE)
str(admissions)

# Q9a
cardiac_all = merge(
    x=cardiac_fu_all,
    y=admissions,
    by.x='patno',
    by.y='patno',
    all.x=TRUE
)
str(cardiac_all)
sum(is.na(cardiac_all$n_admissions))
# 53 no admissions => instead of NA, since they were never admitted it should be 0

# Q9b
cardiac_all$n_admissions[is.na(cardiac_all$n_admissions)] = 0
sum(is.na(cardiac_all$n_admissions)) # 0 => no more NA data
head(cardiac_all[cardiac_all$n_admissions == 0, ])

# Q10
write.table(
    cardiac_all,
    'data/cardiac_all.txt',
    quote=FALSE,
    sep='\t',
    col.names=TRUE,
    row.names=FALSE
)
