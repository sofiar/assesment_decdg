
library(dplyr)
library(tidyverse)
library(ggplot2)

################################## Question 2 ######################################

# 1.

# Load data
GDP_data <- read_csv("GDP_for_R.csv")
population <- read_csv("population_for_R.csv")
WB_groups <- read_csv("WB_groups.csv")

# gather GPD data to get years as a variable
GDP_data  <- gather(GDP_data , key = "Year", value = "GDP", colnames(GDP_data)[5:length(GDP_data)])
population  <- gather(population , key = "Year", value = "population", colnames(population)[5:length(population)])

# combine two data sets (as in q 1)
merged_data <- merge(GDP_data, population, by = c("Country Code",'Year'), all = TRUE)

# now lets merge the data with the WB gruops
# first make both df match the same names
colnames(WB_groups) = c('GroupCode','GroupName','CountryCode','LevelIncome')
colnames(merged_data)[1] = 'CountryCode'
merged_data = merge(merged_data, WB_groups, by = c("CountryCode"), all = TRUE)

# get average GDP per capita for regions AFE and AFW
# First I will remove all rows with missing Group names (see discussion at the end)
merged_data = merged_data[, !is.na(names(merged_data)) & names(merged_data) != ""]
# filter regions needed
merged_filtered = merged_data %>% filter(GroupCode%in%c('AFE','AFW'))
# create weights and variable of total population by region
merged_filtered = merged_filtered %>% group_by(GroupCode) %>% mutate( w = population/sum(population ,na.rm=TRUE))
population_byregion = numeric(dim(merged_filtered)[2])
population_byregion[merged_filtered$GroupCode=='AFE']=sum(merged_filtered$population[merged_filtered$GroupCode=='AFE'],na.rm = TRUE)
population_byregion[merged_filtered$GroupCode=='AFW']=sum(merged_filtered$population[merged_filtered$GroupCode=='AFW'],na.rm = TRUE)
merged_filtered$population_byregion=population_byregion

# get averages by region
averages = merged_filtered %>% group_by(Year,GroupCode) %>% summarise(GDP_pcapita = sum(GDP*w/population,na.rm=TRUE))

# make some plots
# we can se trends by time and by group in the following plot
ggplot(averages)+ geom_point(aes(Year,GDP_pcapita,col=GroupCode))

# The weights used were calculated taking into account the density population of each country,
# when more population density more weight
# we are not considering all countries in this analysis as there are country/years with missing data
# again as in question 1 some imputation methods can be used. Here for example we can also use data from other
# countries in the same region to predict missing data


