# Exercise Optional
# 2026-10-08

# Q1
# Create a function to calculate the area of a circle. Test the function by finding the area of a circle with a diameter of 3.4 cm.
# Can you use it on a vector of data?

circle_area = function(diameter) {
		paste(round(pi * (diameter / 2)^2, 2), ' cm^2')
}
circle_area(10)
circle_area(c(30, 20))


# Q2
# Write a function to convert Fahrenheit to centigrade (oC = (oF - 32) x 5/9). Get your function to print out both the
# temperature you gave it and the converted value, each with a label, so the result reads something
# like “Fahrenheit: 60 oF” followed by “Centigrade: 15.556 oC”.
fahrenheit_to_celc = function(temp) {
		cat(
				'Fahrenheit: ', temp, ' oF', '\n',
				'Centigrade: ',
				round(
						(temp - 32) * 5 / 9, 2
				), ' oC',
				sep=''
		)
}
fahrenheit_to_celc(60)

# Q3
# Create a vector of normally distributed data, of length 100, mean 35 and standard deviation of 15.
# Write a function to calculate the mean, median, and range of the vector,
# print these values out with appropriate labels. Also get the function to plot a histogram
# (as a proportion) of the values and add a density curve.

# Descriptive stats function
desc_stats = function(vec) {
		cat(
				'Mean = ', round(mean(vec, na.rm=TRUE), 2), '\n',
				'Median = ', round(median(vec, na.rm=TRUE), 2), '\n',
				'Range = ', round(diff(range(vec, na.rm=TRUE)), 2),
				sep=''
		)
}
vec_norm = rnorm(100, 35, 15)
vec_norm
desc_stats(vec_norm)

# Histogram + density curve
library(ggplot2)
hist_dens = function(vec) {
		ggplot(data.frame(vec), aes(x=vec)) +
				geom_histogram(bins = 20, aes(y=after_stat(density)), fill='lightblue', color='black') +
				geom_density(color='red', linewidth=1)
}
hist_dens(vec_norm)


# Q4
# Write a function to calculate the median value of a vector of numbers (yes I know there’s a median()
# function already but this is fun!). Be careful with vectors of an even sample size,
# as you will have to take the average of the two central numbers (hint: use modulo %%2
# to determine whether the vector is an odd or an even size).
# Test your function on vectors with both odd and even sample sizes.
find_median = function(vec) {
		sorted_vec = sort(vec)
		if (length(vec) %% 2 != 0){ # Odd length
				cat('Median: ', sorted_vec[ceiling(length(sorted_vec) / 2)])
		} else {
				cat('Median: ', sorted_vec[length(sorted_vec) / 2] + sorted_vec[length(sorted_vec) / 2 + 1] / 2)
		}
}
find_median(seq(from=5, to=102, by=3))


# Q5
# Ricker Model
# N_(t+1) = N_t * e^[ r * (1 - (N_t / K) ) ]
# N_t -> population size at time t
# r -> population growth rate
# K -> carrying capacity; Defaults to 100 but customisable
# t -> time
# N_0 / nzero -> initial population (= r)
ricker = function(
	r,
	nzero,
	t,
	K = 100
) {
	n = numeric(t + 1)
	n[1] = nzero

	for (i in 1:t) {
		n[1+i] = n[i] * exp(r * (1 - (n[i] / K)))
	}
	return n
}

a = ricker(r = 100, nzero = 1, t = 250)
a
