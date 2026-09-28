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
?factor
head(df$sex, n=3)
