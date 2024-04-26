library(dplyr)
library(tidyverse)
library(ggplot2)

################################## Question 3 ######################################

# 1. Propose data quality tests for the GDP data and implement these in a script.
# Describe the tests you perform and explain why.
# 2. Did you find any issues with the data?
# 3. Describe a test for outliers in the data and implement it.
#  Did you find any outliers? If so, describe how you would proceed\deal with these outliers
# before publishing the data.

####################################################################################
####################################################################################

# In order to conduct a data quality test we will: check completeness and accuracy.
# A. Completeness: look at missing data and check whether those values are random or at specific countries/years/periods
# We will check the percentage of missing data by year and by country. If the percentage of missing data
# is more than 85%, we will remove that country from the data set.
# B. Accuracy: we will check the range (min/max) for GDP. We expect to see only positive values
# Please see the implementation below, including additional explanations

####################################################################################
# lets load the data one more time and gather it
GDP_data = read_csv("GDP_for_R.csv")
GDP_data = gather(GDP_data , key = "Year", value = "GDP", colnames(GDP_data)[5:length(GDP_data)])

# There are data of 261 countries during 64 years of data
all_countries = unique(GDP_data$`Country Code`)
all_years = unique(GDP_data$Year)

# lets explore a little more in detail the data

## A. COMPLETNESS: missing values, where are the missing values?
which_na = is.na(GDP_data$GDP)
no_vals = GDP_data[which_na,]

# lets see by country
missing_by_country = sort(table(no_vals$`Country Name`),decreasing = TRUE)
head(missing_by_country)

# British Virgin Islands, Gibraltar Korea, Dem. People's Rep are the ones with all years with missing data
# Followed by St. Martin (French part) with 60 years of missing data and  South Sudan with 56
# Lets get the percentage
percentages_by_country = missing_by_country/64

# lets see by year
missing_by_year = sort(table(no_vals$Year),decreasing = TRUE)
head(missing_by_year)
# 2023 is the one with more missing values (with 216 missing countries), following by 1960 (with 138), and 1961 with 137
percentages_by_year = missing_by_year/261
# 2023 is missing for all countries and it seems that for the first years on the period is where less data is available

# We remove 2023 from the data set for all countries and the completely time series for all countries including not classified data
# with more than 85 % of missing data
countries_to_filter = names(which(percentages_by_country >= 0.85))
GDP_data_filter = GDP_data %>% filter(Year!=2023)
GDP_data_filter = GDP_data_filter %>% filter(!`Country Name`%in%countries_to_filter)

## B. ACCURACY:
# lets first check if the range of the values make sense
range(GDP_data_filter$GDP,na.rm = TRUE)
min(GDP_data_filter$GDP,na.rm = TRUE)
max(GDP_data_filter$GDP,na.rm = TRUE)
ranges_by_country = GDP_data_filter %>% group_by(`Country Name`) %>% summarise(min = min(GDP,na.rm = TRUE),max = max(GDP,na.rm = TRUE) )
plot(ranges_by_country$min)
plot(ranges_by_country$max)
# There are not negative values and the range seems to be correct.
# The range differs by country
# Lets see the mean by coutry
mean_by_country = GDP_data_filter %>% group_by(`Country Code`) %>% summarise(mean = mean(GDP,na.rm=T))
plot(mean_by_country$mean)
boxplot(mean_by_country$mean)

####################################################################################

# To detect outliers, we will first plot the data: general boxplots and
# time series by country. We can visualize the data behavior and check for trends.
# In this case we can see that there is an increasing trend over the years for the value
# of GDP for all countries. We will take that into account during the outlier detection.
# To detect outliers, we will calculate the zscore and define outliers as points with
# |zscore|>3. We take two things into account when calculating the zscore
#
# 1. There is a lot of variability for GDP between countries
# 2. The GDP increases over the years
#
# To address 1, we will divide the points by country.
# To address 2, we will further divide the points into two periods 1960:1991 and 1992:2002.
# Then we calculate the zcore using the mean and standard deviation of the
# corresponding country and subperiod and define as outliers those with
# |zscore|>3.
# Please see the implementation below, including additional explanations

####################################################################################
# Do we have outliers ?
# lets make plots by countries


for (i in 1:11){
  cd = ((i - 1) * 25 + 1):(i * 25)
  p =ggplot(GDP_data_filter %>% filter(`Country Code`%in% all_countries [cd]))+geom_boxplot(aes(y=GDP))+
    facet_wrap(~`Country Code`,scales='free',ncol= 5)
  print(p)
}

for (i in 1:11){
  cd = ((i - 1) * 25 + 1):(i * 25)
  p =ggplot(GDP_data_filter %>% filter(`Country Code`%in% all_countries [cd]))+geom_point(aes(x=Year,y=GDP))+
    facet_wrap(~`Country Code`,scales='free',ncol= 5)
  print(p)
}


# Also according to these plots it seems that the value of GDP is increasing over time for all countries
# So we should consider this when looking for outliers
# I will divide the period of years in two to look for possible outliers: 1960:1991 and 1992:2002 .
# In this way we consider the trending in data. Also, as the range of GDP depends on the Country
# I will perform the analysis also by country
# lets calculate the zscore by country and sub-period and define an observation to be an outlier if |zscore| > 3

# lets create another variable for subperiods
period = numeric(length(GDP_data_filter$Year))
period[GDP_data_filter$Year%in%as.character(1960:1991)] = 'P1'
period[GDP_data_filter$Year%in%as.character(1992:2022)] = 'P2'
GDP_data_filter$period = as.factor(period)

data_zscores = GDP_data_filter %>%group_by(`Country Name`,period) %>%
  mutate(z_score= scale(GDP))

# Lets check  we get numeric values of zscores when there is available data
which(is.na(data_zscores[!is.na(data_zscores$GDP),]$z_score))
data_zscores[!is.na(data_zscores$GDP),][5166,]
data_zscores[!is.na(data_zscores$GDP),][5218,]

ggplot(GDP_data_filter %>% filter(`Country Code`=='MOZ'))+geom_point(aes(x=Year,y=GDP))
ggplot(GDP_data_filter %>% filter(`Country Code`=='HUN'))+geom_point(aes(x=Year,y=GDP))

#For Hungary and Mozambique we have only one observation in the first period that is why we get NaN.
# However looking at the previous plots those values don't seem ouliers

# lets now define the ouliers
range(data_zscores$z_score,na.rm=TRUE) # There are no values below - 3
which_outliers = which(data_zscores$z_score>3)
# so there are the outliers we detected: 10 in total
data_zscores[which_outliers,]


####################################################################################

# In order to deal with the 10 outliers found we will replace them with less extreme values
# Again , as in this case the data have temporal correlation we will consider it in order
# to replace the outliers.
# For each outlier we consider the previous and next value of GDP of the corresponding country.
# We then get the mean between those two and use that value as the replacement.
# In this case we have some missing data, so we should consider that. When
# either the previous or next value is missing, we take the next-next or previous-previous value.
# Please see the implementation below, including additional explanations

####################################################################################

# Lets finally handle the outliers. Lets replace them with less extreme values
# For each outlier we consider the previous and next value of GDP of the corresponding country.
# We just then take the mean between those values and replace it
# We save the data frame corrected and filter in GDP_data_corrected



GDP_data_corrected = GDP_data_filter

for (i in 1:length(which_outliers)){
  curr = data_zscores[which_outliers[i],]
  country_curr = curr$`Country Code`
  year_curr = curr$Year
  prev_year = as.character(as.numeric(year_curr)-1)
  next_year = as.character(as.numeric(year_curr)+1)
  ts_curr = GDP_data_corrected[GDP_data_corrected$`Country Code`==country_curr,]
  val1 = ts_curr[ts_curr$Year==prev_year,]$GDP
  val2 = ts_curr[ts_curr$Year==next_year,]$GDP

  new_val = mean(c(val1,val2))
  # Replace value
  GDP_data_corrected[GDP_data_corrected$`Country Code`==country_curr & GDP_data_corrected$Year==year_curr ,]$GDP = new_val

  }







