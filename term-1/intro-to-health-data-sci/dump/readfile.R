library(readr)
df <- read_csv("nyc-taxi.csv")
df <- subset(df, select=-...1)

View(df)

