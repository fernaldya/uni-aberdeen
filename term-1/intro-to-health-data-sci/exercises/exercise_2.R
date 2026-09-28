# https://alexd106.github.io/PU5058/exercise_2.html
# 2026-09-24

# 2.
log10(100)
log(2.9)
log2(2^100)

# 3.
d = 20
area = pi * (d / 2)^2
print(area)

# 4.
weights = c(69, 62, 57, 59, 59, 64, 56, 66, 67, 66, 65)
weights[1] # 1 indexed
# print(weights)

# 5.
mean_weights <- mean(weights)
var(weights)
sd(weights)
length(weights)

# Range (and with step)
x = 1:10
print(x)

y = seq(from=1, to=10, by=1)
print(y)

# 6. summary
heights = c(112, 102, 83, 84, 99, 90, 77, 112, 133, 112, 165)
summary(heights)

# Fetch all the heights shorter than 99
shorter = heights[heights < 99]
print(shorter)

# 7.
# BMI
bmi = weights / (heights / 100)^2
bmi

# 8. seq
seq1 = seq(from=0, to=1, by=0.1)
seq1

seq2 = seq(from=10, to=1, by=-0.5)
seq2
# Alternative using rev
seq2_ = seq(from=1, to=10, by=0.5)
seq2_
seq2_reverse = rev(seq2_)
seq2_reverse

# 9. rep
# rep (times & each)
rep1 = rep(c(1,2,3), times=3)
rep1

rep2 = rep(c('a','c','e','g'), each=3)
rep2

# 10. sort method
heights_sorted = sort(heights)
heights_sorted

# 11.
child_names = c("Alfred", "Barbara", "James", "Jane", "John", "Judy", "Louise", "Mary", "Ronald", "William")
child_names
heights

# 12.
# Order child_names by their height
height_order = order(heights) # Fetch the index of the sorted values from lowest to highest (default)
height_order
names_sort = child_names[height_order]
names_sort

# 13.
mydata = c(2, 4, 1, 6, 8, 5, NA, 4, 7)
mydata
mean(mydata) # Returns NA because of a missing value
mean(mydata, na.rm=TRUE) # Strips NA values before calculating mean


# 14.
ls()
rm(seq1)
seq1
