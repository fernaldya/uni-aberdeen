# https://alexd106.github.io/PU5058/exercise_2.html
# 2026-09-24

log10(100)
log(2.9)
log2(2^100)

d = 20
area = pi * (d / 2)
print(area)

weights = c(69, 62, 57, 59, 59, 64, 56, 66, 67, 66, 65)
weights[1] # 1 indexed
# print(weights)

mean_weights <- mean(weights)
var(weights)
sd(weights)
length(weights)

# Range (and with step)
x = 1:10
print(x)

y = seq(from=1, to=10, by=1)
print(y)

heights = c(112, 102, 83, 84, 99, 90, 77, 112, 133, 112, 165)
summary(heights)

# Fetch all the heights shorter than 99
shorter = heights[heights < 99]
print(shorter)

# BMI
bmi = weights / (heights / 100)^2
bmi
