
Validation of Power in One-Way ANOVA
------------------------------------

Using the formulas below, we can calculate the means for between designs with one factor (One-Way ANOVA). Using the formula also used in Albers & Lakens (2018), we can determine the means that should yield a specified effect sizes (expressed in Cohen's f).

``` r
mu_from_ES <- function(K, ES){ # provides the vector of population means for a given population ES and nr of groups
  f2 <- ES/(1-ES)
  if(K == 2){
    a <- sqrt(f2)
    muvec <- c(-a,a)
  }
  if(K == 3){
    a <- sqrt(3*f2/2)
    muvec <- c(-a, 0, a)
  }
  if(K == 4){
    a <- sqrt(f2)
    muvec <- c(-a, -a, a, a)
  } # note: function gives error when K not 2,3,4. But we don't need other K.
  return(muvec)
}
```

Eta-squared (identical to partial eta-squared for One-Way ANOVA's) has benchmarks of .0099, .0588, and .1379 for small, medium, and large effect sizes (cohen, 1988).

Installation
------------

We install the functions:

``` r
# Install the two functions from GitHub by running the code below:

source("https://raw.githubusercontent.com/Lakens/ANOVA_power_simulation/master/ANOVA_design.R")
source("https://raw.githubusercontent.com/Lakens/ANOVA_power_simulation/master/ANOVA_power.R")
```

Three conditions, large effect size
-----------------------------------

We can simulate a One-Way ANOVA with a specific alpha, sample size and effect size, to achieve a specified statistical power. Below we forst perform a power analysis for n = 5000 per condition, 3 groups (K), sd = 1, and a desired power of .8, or 80%.

``` r
K <- 3
n <- 5000
sd <- 1
r <- 0

#Calculate f when running simulation with n = 5000
library(pwr)
f <- pwr.anova.test(n=n,k=K,power=0.8,sig.level=0.05)$f
f2 <- f^2
ES <- f2/(f2+1)
ES
```

    ## [1] 0.0006417212

``` r
mu <- mu_from_ES(K = K, ES = ES)

string = paste(K,"b",sep="")
```

Because of the large sample size, we have 80% power for an effect size (eta-squared) of 0.0006417212. We achieve this effect size if we have 3 groups with means of -0.03103546 0.00000000 0.03103546. So let's simulate data with these means, and check if we get 80% power.

``` r
design_result <- ANOVA_design(string = string,
                   n = n, 
                   mu = mu, 
                   sd = sd, 
                   r = r, 
                   p_adjust = "none",
                   labelnames = c("factor1", "level1", "level2", "level3"))
```

![](validation_power_between_files/figure-markdown_github/unnamed-chunk-4-1.png)

``` r
ANOVA_power(design_result, nsims = nsims)
```

    ## Power and Effect sizes for ANOVA tests
    ##               power effect size
    ## anova_factor1    83       0.001
    ## 
    ## Power and Effect sizes for contrasts
    ##                                                   power effect size
    ## paired_comparison_factor1_level1 - factor1_level2    39       -0.03
    ## paired_comparison_factor1_level1 - factor1_level3    91       -0.06
    ## paired_comparison_factor1_level2 - factor1_level3    36       -0.03

The results of the simulation are indeed very close to 80%.

Four conditions, very large effect size
---------------------------------------

We can simulate a One-Way ANOVA with an alpha of 0.01, a sample size of 15 per group for four groups, and an effect size to achieve 90% power.

``` r
K <- 4
n <- 15
sd <- 1
r <- 0

#Calculate f when running simulation with n = 5000
library(pwr)
f <- pwr.anova.test(n=n,k=K,power=0.95,sig.level=0.05)$f
f2 <- f^2
ES <- f2/(f2+1)
ES
```

    ## [1] 0.2349157

``` r
mu <- mu_from_ES(K = K, ES = ES)

string = paste(K,"b",sep="")
```

We have 95% power for an effect size (eta-squared) of 0.2349157. So let's simulate data with this effect size, and check if we get 95% power.

``` r
design_result <- ANOVA_design(string = string,
                   n = n, 
                   mu = mu, 
                   sd = sd, 
                   r = r, 
                   p_adjust = "none",
                   labelnames = c("factor1", "level1", "level2", "level3"))
```

![](validation_power_between_files/figure-markdown_github/unnamed-chunk-6-1.png)

``` r
ANOVA_power(design_result, nsims = nsims)
```

    ## Power and Effect sizes for ANOVA tests
    ##               power effect size
    ## anova_factor1    91       0.263
    ## 
    ## Power and Effect sizes for contrasts
    ##                                                   power effect size
    ## paired_comparison_factor1_level1 - factor1_level2    10       -0.06
    ## paired_comparison_factor1_level1 - factor1_level3    86       -1.13
    ## paired_comparison_factor1_level1 - factor1_NA        84       -1.09
    ## paired_comparison_factor1_level2 - factor1_level3    80       -1.07
    ## paired_comparison_factor1_level2 - factor1_NA        77       -1.03
    ## paired_comparison_factor1_level3 - factor1_NA         5        0.04

The result of the simulation is a power that is very close to the intended 95% power. Note that the mean observed effect size is larger than the true effect size (because eta-squared is upwardly biased, see Albers & Lakens, 2018).

Two conditions, medium effect size
----------------------------------

We can simulate a One-Way ANOVA with an alpha of 0.05 sample size of 50 per group, and an effect size to achieve 95% power.

``` r
K <- 2
n <- 50
sd <- 1
r <- 0

#Calculate f when running simulation with n = 5000
library(pwr)
f <- pwr.anova.test(n=n,k=K,power=0.95,sig.level=0.05)$f
f2 <- f^2
ES <- f2/(f2+1)
ES
```

    ## [1] 0.1170461

``` r
mu <- mu_from_ES(K = K, ES = ES)

string = paste(K,"b",sep="")
```

We have 95% power for an effect size (eta-squared) of 0.1170461. So let's simulate data with this effect size, and check if we get 95% power.

``` r
design_result <- ANOVA_design(string = string,
                   n = n, 
                   mu = mu, 
                   sd = sd, 
                   r = r, 
                   p_adjust = "none",
                   labelnames = c("factor1", "level1", "level2"))
```

![](validation_power_between_files/figure-markdown_github/unnamed-chunk-8-1.png)

``` r
power_result <- ANOVA_power(design_result, nsims = 1000)
```

    ## Power and Effect sizes for ANOVA tests
    ##               power effect size
    ## anova_factor1  94.9        0.12
    ## 
    ## Power and Effect sizes for contrasts
    ##                                                   power effect size
    ## paired_comparison_factor1_level1 - factor1_level2  94.9       -0.73

The result of the simulation is a power that is very close to the intended 90% power.

We can plot the p-value distribution for the ANOVA:

``` r
power_result$plot
```

![](validation_power_between_files/figure-markdown_github/unnamed-chunk-9-1.png)
