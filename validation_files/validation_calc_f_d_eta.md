
Validation of formula to calc f, d, and eta from mu and sd
----------------------------------------------------------

This function allows you to calculate f, d and eta squared following Cohen, 1988, p 277, for three types of patterns. The patterns are: 1. Minimum variability: one mean at each end of d, the remaining k- 2 means all at the midpoint. 2. Intermediate variability: the k means equally spaced over d. 3. Maximum variability: the means all at the end points of d.

For each of these patterns, there is a fixed relationship between f and d for any given number of means, k.

Pattern 1. For any given range of means, d, the minimum standard deviation, f1, results when the remaining k - 2 means are concentrated at the mean of the means (0 when expressed in standard units), i.e., half-way between the largest and smallest.

Pattern 2. A pattern of medium variability results when the k means are equally spaced over the range, and therefore at intervals of d/(k- 1).

Pattern 3. It is demonstrable and intuitively evident that for any given range the dispersion which yield~ the maximum standard deviation has the k means falling at both extremes of the range. When k is even, 1/2k fall at -1/2d and the other 1/2k fall at +1/2d; when k is odd, (k + 1 )/2 of the means fall at either end and the (k- 1)/2 remaining means at the other. With this pattern, for all even numbers of means, use formula (8.2.12). When k is odd, and there is thus one more mean at one extreme than at the other, use formula (8.2.13).

Installation
------------

We install the function:

``` r
# Install the function from GitHub by running the code below:

source("https://raw.githubusercontent.com/Lakens/ANOVA_power_simulation/master/calc_f_d_eta.R")
```

Minimum variability
-------------------

For example, 7 (=k) means dispersed in Pattern 1 would have the (standardized) values -1/2d, 0, 0, 0, 0, 0, +1/2d. Thus, a set of 7 population means spanning half a within-population standard deviation would have f= .267(.5) = .13.

This can be reproduced by setting the means to -0.25 and 0.25 (and all others to 0) and the sd to 1. This way d = 0.5 (as in Cohen's example).

``` r
res <- calc_f_d_eta(mu = c(-0.25, 0, 0, 0, 0, 0, 0.25), sd = 1, variability = "minimum")
res$f
```

    ## [1] 0.1336306

``` r
res$d
```

    ## [1] 0.5

Medium variability
------------------

For example, for k = 7 i.e., 7 equally spaced means would have the values -1/2d, -1/3d, -1/6d, 0, +1/6d, +1/3d, and +1/2d, and a standard deviation equal to one-third of their range. For a range of half a within-population standard deviation, f2 = .333(.5) = .17

This can be reproduced by setting the means to -1/2, -1/3, -1/6, 0, 1/6, 1/3, 1/2 and the sd to 2. This way d = 0.5 (as in Cohen's example).

``` r
res <- calc_f_d_eta(mu = c(-1/2, -1/3, -1/6, 0, 1/6, 1/3, 1/2), sd = 2, variability = "medium")
res$f
```

    ## [1] 0.1666667

``` r
res$d
```

    ## [1] 0.5

Maximum variability
-------------------

For example, for k = 7 means in Pattern 3 (4 means at either -1/2d or +1/2d, 3 means at the other). If, as before, we posit a range of half a within-population standard deviation, f3 = .495(.5) = .25.

``` r
res <- calc_f_d_eta(mu = c(0.25, 0.25, 0.25, 0.25, -0.25, -0.25, -0.25), sd = 1, variability = "maximum")
res$f
```

    ## [1] 0.2474358

``` r
res$d
```

    ## [1] 0.5
