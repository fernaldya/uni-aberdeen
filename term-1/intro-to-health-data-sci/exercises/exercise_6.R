# Exercise 6
# Date: 2026-10-07
# Author: Fernaldy Aristo Wirjowerdojo

library(ggplot2)
setwd('exercises')

# Q2
scotpho = read.table('data/scotpho_alcohol_admissions.txt', header=TRUE, sep='\t', stringsAsFactors=TRUE)
str(scotpho)

# Q4
summary(scotpho)

table(scotpho$area_type)
# Council area has 320 rows of data, Scotland has 10

table(scotpho$area_name)
unique(table(scotpho$area_name))
table(scotpho$year)
# 33 areas and each area has 10 points of data (year)

range(scotpho$year)
# 2010 - 2019

# Q5
scot = scotpho[scotpho$area_name == 'Scotland',]
nrow(scot)
summary(scot)
str(scot)

ggplot(data=scot, mapping=aes(x=year, y=measure)) +
  geom_point() +
  geom_line()
# Readers won't be able to understand what this graph is; No title, year labels is odd, no indication of what measure is

ggplot(data=scot, mapping=aes(x=year, y=measure)) +
  geom_point() +
  geom_smooth(method='lm', se=FALSE)


# Q6a
areas = c('Glasgow City', 'Aberdeenshire', 'Scotland')

# Q6b
three_areas = scotpho[scotpho$area_name %in% areas,]
nrow(three_areas)

ggplot(data=three_areas, mapping=aes(x=year, y=measure, colour=area_name)) +
  geom_point() +
  geom_line(linewidth=1)
  # geom_smooth(method='lm', se=FALSE)


# Q7a
cols = palette.colors(3, palette = "Okabe-Ito")
ggplot(data=three_areas, mapping=aes(x=year, y=measure, colour=area_name)) +
  geom_line(linewidth=1) +
  scale_colour_manual(values=cols)

# Q7b
ggplot(data=three_areas, mapping=aes(x=year, y=measure, colour=area_name)) +
  geom_line(linewidth=1) +
  scale_colour_manual(values=grey(c(0, 0.64, 0.62)))

# Q7c
ggplot(data=three_areas, mapping=aes(
    x=year, y=measure,
    colour=area_name
  )) +
  geom_line(linewidth=1) +
  scale_colour_manual(values=cols)


# Q8
admissions_plot = ggplot(data=three_areas, mapping=aes(
    x=year, y=measure,
    colour=area_name, line_type=area_name
  )) +
  geom_line() +
  scale_colour_manual(values=cols) +
  scale_x_continuous(breaks=seq(2010, 2019, 2)) + # 8a
  scale_y_continuous(limits=c(0, 1600)) + # 8b
  theme_minimal() + # Q8c
  theme(
    legend.position='bottom',
    plot.caption = element_text(hjust = 0.5) # Center caption
  ) +
  labs(
    x='Year', y='Hospital admissions (per 100,000 people)', title='Alcohol Related Hospital Admission',
    caption='Source: Scottish Public Health Observatory. Rates are age-sex standardised.',
    colour=NULL, linetype=NULL
  ) # Q8

admissions_plot

# Q9
ggsave('output/Ex6-Q8.pdf', width=10, height=5.625, dpi=300)
ggsave('output/Ex6-Q8.png', width=10, height=5.625, dpi=300)

# Q10
ggplot(data=three_areas, mapping=aes(
    x=year, y=measure,
    colour=area_name, linetype=area_name
  )) +
  geom_line(linewidth = 1) +
  geom_errorbar(aes(ymin = lower_confidence_interval, ymax = upper_confidence_interval),
    linetype = 'solid', width = 0.2) +
  geom_point(size = 2) +
  scale_colour_manual(values=cols) +
  scale_x_continuous(breaks=seq(2010, 2019, 2)) +
  scale_y_continuous(limits=c(0, 1600)) +
  theme_minimal() +
  theme(
    legend.position='bottom',
    plot.caption = element_text(hjust = 0.5) # Center caption
  ) +
  labs(
    x='Year', y='Hospital admissions (per 100,000 people)', title='Alcohol Related Hospital Admission',
    caption='Source: Scottish Public Health Observatory. Rates are age-sex standardised.',
    colour=NULL, linetype=NULL
  )

ggsave('output/Ex6-Q10.png', width=10, height=5.625, dpi=300)
