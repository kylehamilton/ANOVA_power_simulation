plot_power_oneway_between <- function(design_result, max_n){
  
  string = design_result$string
  mu = design_result$mu
  sd <- design_result$sd
  r <- design_result$r
  p_adjust = design_result$p_adjust
  labelnames = c(design_result$factornames[[1]], design_result$labelnames[[1]])

  n_vec <- seq(from = 5, to = max_n)
  
  power_A <- numeric(length(n_vec))

  for (i in 1:length(n_vec)){
    design_result <- ANOVA_design(string = string,
                                  n = n_vec[i], 
                                  mu = mu, 
                                  sd = sd, 
                                  r = r, 
                                  p_adjust = p_adjust,
                                  labelnames = labelnames)
    
    power_res <- power_oneway_between(design_result)
    
    power_A[i] <- power_res$power*100
  }
  
  res_df <- data.frame(n_vec, power_A)
  
  library(ggplot2)
  library(gridExtra)
  p1 <- ggplot(data=res_df, aes(x = n_vec, y = power_A)) +
    geom_line( size=1.5) +
    scale_x_continuous(limits = c(0, max(n_vec))) + 
    scale_y_continuous(limits = c(0, 100)) +
    theme_bw() +
    labs(x="Sample size", y = "Power Factor A")
  
  invisible(list(p1 = p1,
                 power_df = data.frame(paste("f = ",
                                             round(power_res$Cohen_f,2)), 
                                       n_vec, 
                                       power_A)))
}