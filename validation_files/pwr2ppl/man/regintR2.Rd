% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/regintR2.R
\name{regintR2}
\alias{regintR2}
\title{Compute Power for Regression Interaction (R2 Change Approach)}
\usage{
regintR2(R2Mod, R2Ch, mod_pred, ch_pred, nlow, nhigh, by = 1,
  alpha = 0.05)
}
\arguments{
\item{R2Mod}{Full Model R2}

\item{R2Ch}{Change in R2 Added by Interaction}

\item{mod_pred}{Full Model Number of Predictors}

\item{ch_pred}{Change Model Number of Predictors}

\item{nlow}{starting sample size}

\item{nhigh}{ending sample size}

\item{by}{incrimental increase in sample (e.g. nlow = 10, nhigh = 24, by = 2, produces estimates of 10, 12, and 14)}

\item{alpha}{Type I error (default is .05)}
}
\value{
Power for Regression Interaction (R2 Change Approach)
}
\description{
Compute Power for Regression Interaction (R2 Change Approach)
}
