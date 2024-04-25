library(dplyr)
library(tidyverse)

################################## Question 1 ######################################
# 1.

# Load data
GDP_data <- read_csv("GDP_for_R.csv")
population <- read_csv("population_for_R.csv")
WB_groups <- read_csv("WB_groups.csv")

# gather GPD data to get years as a variable
GDP_data  <- gather(GDP_data , key = "Year", value = "GDP", colnames(GDP_data)[5:length(GDP_data)])
population  <- gather(population , key = "Year", value = "population", colnames(population)[5:length(population)])

# combine two data sets
merged_data <- merge(GDP_data, population, by = c("Country Name",'Year'), all = TRUE)

# get GDP per capita (when possible)
merged_data %>% group_by(Year,`Country Name`) %>% summarise(GDP_pcapita = GDP/population)

# 2.
# We cannot calculate GDP per capita for all Country/ year combinations because there are missins data
# Lets see how many
# Regarding populatio data we have 418 missing values and 3851 regarding GDP
sum(is.na(merged_data$population))
sum(is.na(merged_data$GDP))

#3 .
# As there are missing data a way to improve coverage would be try to estimate missing data.
# For population data a possibility, would be estimate the missing value extrapolating from the data available.
# For example is population data is missing in Albania in 1980, but that is information is available for 1979 and 1981,
# we can take the mean between those values and replace the missing value. The same could be done for GDP data
# Also, if there is available information and some previous knowledge  some times a prediction model (like linear regression)
# could also be used in order to predict missing data of GDP


#





