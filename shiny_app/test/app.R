#TEST APP
#Added labels back
#Adjusted effect size for between subjects pairwise (sample size) and partial eta squared (median)
#Save labelnames has been removed

###############
# Load libraries ----
###############

library(shiny)
library(mvtnorm)
library(afex)
library(emmeans)
library(ggplot2)
library(gridExtra)
library(reshape2)
library(sendmailR)


# Define User Interface for simulations
ui <- fluidPage(
  titlePanel("ANOVA Simulation"),
  
  #Panel to define ANOVA design
  column(4, wellPanel(  
    
    h4("This is an alpha version of an app to calculate power for ANOVA designs through simulation. It is made by ", a("Aaron Caldwell", href="https://twitter.com/ExPhysStudent"), "and ", a("Daniel Lakens", href="https://twitter.com/Lakens"),"and we appreciate hearing any feedback you have as we develop this app."),
    
    h4("Add numbers for each factor that specify the number of levels in the factors (e.g., 2 for a factor with 2 levels). Add a 'w' after the number for within factors, and a 'b' for between factors. Seperate factors with a * (asteriks). Thus '2b*3w' is a design with two factors, the first of which has 2 between levels, and the second of which has 3 within levels."),
    
    textInput(inputId = "design", label = "Design Input",
              value = "2b*2w"),
    
    h4("Specify one word for each level of each factor (e.g., old and yound for a factor age with 2 levels)."),
    
    textInput("labelnames", label = "Factor Labels",
              value = "old, young, fast, slow"),
    
    sliderInput("sample_size",
                label = "Sample Size per Cell",
                min = 3, max = 200, value = 80),
    
    textInput(inputId = "sd", label = "Standard Deviation",
              value = 1.03),
    
    h4("Specify the correlation for within subjects factors. Note: the standard deviation cannot be numerically smaller than the correlation"),
    
    sliderInput("r",
                label = "Correlation",
                min = 0, max = 1, value = 0.87),
    
    h4("Note that for each cell in the design, a mean must be provided. Thus, for a '2b*3w' design, 6 means need to be entered. Means need to be entered in the correct order. ANOVA_design outputs a plot so you can check if you entered means correctly. The general principle is that the code generates factors, indicated by letters of the alphabet, (i.e., a, b, and c). Levels are indicated by numbers (e.g., a1, a2, a3, etc). Means are entered in the following order for a 3 factors design: a1, b1, c1, a1, b1, c2, a1, b2, c1, a1, b2, c2, a2, b1, c1, a2, b1, c2, a2, b2, c1, a2, b2, c2."),
    
    textInput("mu", label = "Vector of Means", 
              value = "1.03, 1.21, 0.98, 1.01"),
    
    selectInput("p_adjust", h3("Adjustment method for multiple comparisons"), 
                choices = list("None" = "none", "Holm-Bonferroni" = "holm",
                               "Bonferroni" = "bonferroni",
                               "False Discovery Rate" = "fdr"), selected = 1),
    #Button to initiate the design
    h4("Click the button below to set up the design - a graph will be displayed with the means as you specified them. If this graph is as you intended, you can run the simulation."),
    
    actionButton("designBut","Set-Up Design"),
    
    #Conditional; once design is clicked. Then settings for power simulation can be defined
    conditionalPanel("input.designBut >= 1",
                     
                     fluidRow(
                       div(id = "login",
                           wellPanel( h4("If you want to send your results as an email, please enter your email address with angle brackets (<address@email.com>) and a subject line. Warning: this email may end up in your spam folder"),
                                     textInput("to", label = "To: inlclude angle brackets < >", placeholder = "<address@email.com>"),
                                     textInput("sub","Subject:")
                                      
                           )
                       )),
                     
                     sliderInput("sig",
                                 label = "Alpha Level",
                                 min = 0, max = 1, value = 0.05),
                     h4("To test out the app, keep the number of simulations to 100. To get more accurate results, increase the nummber of simulations."),
                     sliderInput("nsims", 
                                 label = "Number of Simulations",
                                 min = 100, max = 10000, value = 100, step = 100),
                     h4("Click the button below to start the simulation."),
                     actionButton("sim", "Simulate -> Print Results"),
                     actionButton("mailButton",label = "Simulate -> Email Results"))
    
    
  )),
  
  
  #Output for Design
  column(5,  
         conditionalPanel("input.designBut >= 1", 
                          h3("Design for Simulation")),
         
         verbatimTextOutput("DESIGN"),
         
         plotOutput('plot'),
         
         tableOutput("corMat")),
  #output for Simulation
  column(4, 
         conditionalPanel("input.sim >= 1", 
                          h3("Simulation Results")),
         
         tableOutput('tableMain'),
         
         tableOutput('tablePC') 
  )
)



# Define server logic 

server <- function(input, output) {
  
  v <- reactiveValues(data = NULL)
  
  
  #ANOVA design function; last update: 07.25.2018
  ANOVA_design <- function(string, n, mu, sd, r, p_adjust, labelnames){
    ###############
    # 1. Specify Design and Simulation----
    ###############
    # String used to specify the design
    # Add numers for each factor with 2 levels, e.g., 2 for a factor with 2 levels
    # Add a w after the number for within factors, and a b for between factors
    # Seperate factors with a * (asteriks)
    # Thus "2b*3w) is a design with 2 between levels, and 3 within levels
    
    #Check if design an means match up - if not, throw an error and stop
    if(prod(as.numeric(strsplit(string, "\\D+")[[1]])) != length(mu)){stop("the length of the vector with means does not match the study design")}
    
    ###############
    # 2. Create Dataframe based on Design ----
    ###############
    
    #Count number of factors in design
    factors <- length(as.numeric(strsplit(string, "\\D+")[[1]]))
    
    #Specify within/between factors in design: Factors that are within are 1, between 0
    design <- strsplit(gsub("[^A-Za-z]","",string),"",fixed=TRUE)[[1]]
    design <- as.numeric(design == "w") #if within design, set value to 1, otherwise to 0
    
    sigmatrix <- matrix(r, length(mu),length(mu)) #create temp matrix filled with value of correlation, nrow and ncol set to length in mu
    diag(sigmatrix) <- sd # replace the diagonal with the sd
    
    #Create the data frame. This will be re-used in the simulation (y variable is overwritten) but created only once to save time in the simulation
    df <- as.data.frame(rmvnorm(n=n,
                                mean=mu,
                                sigma=sigmatrix))
    df$subject<-as.factor(c(1:n)) #create temp subject variable just for merging
    #Melt dataframe
    df <- melt(df, 
               id.vars = "subject", 
               variable.name = "cond",
               value.name = "y")
    
    # Let's break this down - it's a bit tricky. First, we want to create a list of a1 a2 b1 b2 that will indicate the factors. 
    # We are looping this over the number of factors.
    # This: as.numeric(strsplit(string, "\\D+")[[1]]) - takes the string used to specify the design and turn it in a list. 
    # we take the letters from the alfabet: paste(letters[[j]] and add numbers 1 to however many factors there as: 1:as.numeric(strsplit(string, "\\D+")[[1]])[j], sep="")
    # We this get e.g. ,a1 a2 - we repeat these each: n*(2^(factors-1)*2)/(2^j) and them times:  (2^j/2) to get a list for each factor
    # We then bind these together with the existing dataframe.
    for(j in 1:factors){
      df <- cbind(df, as.factor(unlist(rep(as.list(paste(letters[[j]], 
                                                         1:as.numeric(strsplit(string, "\\D+")[[1]])[j], 
                                                         sep="")), 
                                           each = n*prod(as.numeric(strsplit(string, "\\D+")[[1]]))/prod(as.numeric(strsplit(string, "\\D+")[[1]])[1:j]),
                                           times = prod(as.numeric(strsplit(string, "\\D+")[[1]]))/prod(as.numeric(strsplit(string, "\\D+")[[1]])[j:factors])
      ))))
    }
    #Rename the factor variables that were just created
    names(df)[4:(3+factors)] <- letters[1:factors]
    
    #Create subject colum (depends on design)
    subject <- 1:n #Set subject to 1 to the number of subjects collected
    
    for(j2 in length(design):1){ #for each factor in the design, from last to first
      #if w: repeat current string as often as the levels in the current factor (e.g., 3)
      #id b: repeat current string + max of current subject
      if(design[j2] == 1){subject <- rep(subject,as.numeric(strsplit(string, "\\D+")[[1]])[j2])}
      subject_length <- length(subject) #store current length - to append to string of this length below
      if(design[j2] == 0){
        for(j3 in 2:as.numeric(strsplit(string, "\\D+")[[1]])[j2]){
          subject <- append(subject,subject[1:subject_length]+max(subject))
        }
      }
    }
    
    #Overwrite subject columns in df
    df$subject <- subject
    
    ###############
    # 3. Specify factors for formula ----
    ###############
    
    #one factor
    if(factors == 1 & sum(design) == 1){frml1 <- as.formula("y ~ a + Error(subject/a)")}
    if(factors == 1 & sum(design) == 0){frml1 <- as.formula("y ~ a + Error(1 | subject)")}
    
    if(factors == 2){
      if(sum(design) == 2){frml1 <- as.formula("y ~ a*b + Error(subject/a*b)")}
      if(sum(design) == 0){frml1 <- as.formula("y ~ a*b  + Error(1 | subject)")}
      if(all(design == c(1, 0)) == TRUE){frml1 <- as.formula("y ~ a*b + Error(subject/a)")}
      if(all(design == c(0, 1)) == TRUE){frml1 <- as.formula("y ~ a*b + Error(subject/b)")}
    }
    
    if(factors == 3){
      if(sum(design) == 3){frml1 <- as.formula("y ~ a*b*c + Error(subject/a*b*c)")}
      if(sum(design) == 0){frml1 <- as.formula("y ~ a*b*c + Error(1 | subject)")}
      if(all(design == c(1, 0, 0)) == TRUE){frml1 <- as.formula("y ~ a*b*c + Error(subject/a)")}
      if(all(design == c(0, 1, 0)) == TRUE){frml1 <- as.formula("y ~ a*b*c + Error(subject/b)")}
      if(all(design == c(0, 0, 1)) == TRUE){frml1 <- as.formula("y ~ a*b*c + Error(subject/c)")}
      if(all(design == c(1, 1, 0)) == TRUE){frml1 <- as.formula("y ~ a*b*c + Error(subject/a*b)")}
      if(all(design == c(0, 1, 1)) == TRUE){frml1 <- as.formula("y ~ a*b*c + Error(subject/b*c)")}
      if(all(design == c(1, 0, 1)) == TRUE){frml1 <- as.formula("y ~ a*b*c + Error(subject/a*c)")}
    }
    
    #Specify second formula used for plotting
    if(factors == 1){frml2 <- as.formula("~a")}
    if(factors == 2){frml2 <- as.formula("~a+b")}
    if(factors == 3){frml2 <- as.formula("~a+b+c")}
    
    ############################################
    #Specify factors for formula ###############
    design_list <- unique(apply((df)[4:(3+factors)], 1, paste, collapse=""))
    
    ###############
    # 4. Create Covariance Matrix ----
    ###############
    
    #Create empty matrix
    sigmatrix <- data.frame(matrix(ncol=length(mu), nrow = length(mu)))
    
    #General approach: For each factor in the list of the design, save the first item (e.g., a1b1)
    #Then for each factor in the design, if 1, set number to wildcard
    
    
    for(i1 in 1:length(design_list)){
      current_factor <- design_list[i1]
      current_factor <- unlist(strsplit(current_factor,"[a-z]"))
      current_factor <- current_factor[2:length(current_factor)]
      for(i2 in 1:length(design)){
        #We set each number that is within to a wildcard, so that all within subject factors are matched
        
        
        if(design[i2]==1){current_factor[i2] <- "*"}
        
        #depracated
        #if(design[i2] == 1){substr(current_factor, i2*2,  i2*2) <- "*"} 
      }
      ifelse(factors == 1, current_factor <- paste0(c("a"),current_factor, collapse=""),
             ifelse(factors == 2, current_factor <- paste0(c("a","b"),current_factor, collapse=""),
                    current_factor <- paste0(c("a","b","c"),current_factor, collapse="")))
      
      sigmatrix[i1,]<-as.numeric(grepl(current_factor, design_list)) # compare factors that match with current factor, given wildcard, save list to sigmatrix
    }
    
    sigmatrix <- as.matrix(sigmatrix*r)
    diag(sigmatrix) <- sd # replace the diagonal with the sd
    
    # We perform the ANOVA using AFEX
    aov_result<- suppressMessages({aov_car(frml1, #here we use frml1 to enter fromula 1 as designed above on the basis of the design 
                                           data=df,
                                           anova_table = list(es = "pes", p_adjust_method = p_adjust))}) #This reports PES not GES
    
    # pairwise comparisons
    pc <- suppressWarnings({pairs(emmeans(aov_result, frml2), adjust = p_adjust)})
    
    ###############
    # 6. Create plot of means to vizualize the design ----
    ###############
    
    labelnames1 <- labelnames[1:as.numeric(strsplit(string, "\\D+")[[1]])[1]]
    if(factors > 1){labelnames2 <- labelnames[(as.numeric(strsplit(string, "\\D+")[[1]])[1] + 1):((as.numeric(strsplit(string, "\\D+")[[1]])[1] + 1) + as.numeric(strsplit(string, "\\D+")[[1]])[2] - 1)]}
    if(factors > 2){labelnames3 <- labelnames[(as.numeric(strsplit(string, "\\D+")[[1]])[2] + as.numeric(strsplit(string, "\\D+")[[1]])[1] + 1):((as.numeric(strsplit(string, "\\D+")[[1]])[2] + as.numeric(strsplit(string, "\\D+")[[1]])[1] + 1) + as.numeric(strsplit(string, "\\D+")[[1]])[3] - 1)]}
    
    if(factors == 1){labelnames <- list(labelnames1)}
    if(factors == 2){labelnames <- list(labelnames1,labelnames2)}
    if(factors == 3){labelnames <- list(labelnames1,labelnames2,labelnames3)}
    
    
    df_means <- data.frame(mu, SE = sd / sqrt(n))
    for(j in 1:factors){
      df_means <- cbind(df_means, as.factor(unlist(rep(as.list(paste(labelnames[[j]], 
                                                                     sep="")), 
                                                       each = prod(as.numeric(strsplit(string, "\\D+")[[1]]))/prod(as.numeric(strsplit(string, "\\D+")[[1]])[1:j]),
                                                       times = prod(as.numeric(strsplit(string, "\\D+")[[1]]))/prod(as.numeric(strsplit(string, "\\D+")[[1]])[j:factors])
      ))))
    }
    
    if(factors == 1){names(df_means)<-c("mu","SE","a")}
    if(factors == 2){names(df_means)<-c("mu","SE","a","b")}
    if(factors == 3){names(df_means)<-c("mu","SE","a","b","c")}
    
    if(factors == 1){meansplot = ggplot(df_means, aes(y = mu, x = a))}
    if(factors == 2){meansplot = ggplot(df_means, aes(y = mu, x = a, fill=b))}
    if(factors == 3){meansplot = ggplot(df_means, aes(y = mu, x = a, fill=b)) + facet_wrap(  ~ c)}
    
    meansplot = meansplot +
      geom_bar(position = position_dodge(), stat="identity") +
      geom_errorbar(aes(ymin = mu-SE, ymax = mu+SE), 
                    position = position_dodge(width=0.9), size=.6, width=.3) +
      coord_cartesian(ylim=c((.7*min(mu)), 1.2*max(mu))) +
      theme_bw() + ggtitle("Means for each condition in the design")
    #print(meansplot)  
    
    # Return results in list()
    invisible(list(df = df,
                   design = design,
                   design_list = design_list, 
                   factors = factors, 
                   frml1 = frml1, 
                   frml2 = frml2, 
                   mu = mu, 
                   n = n, 
                   p_adjust = p_adjust, 
                   sigmatrix = sigmatrix,
                   string = string,
                   labelnames = labelnames,
                   meansplot = meansplot))
  }
  
  #ANOVA simulation function; last update: 07.25.2018
  ANOVA_power <- function(ANOVA_design, alpha, nsims){
    if(missing(alpha)) {
      alpha<-0.05
    }
    string <- ANOVA_design$string #String used to specify the design
    
    # Specify the parameters you expect in your data (sd, r for within measures)
    
    #number of subjects you will collect (for each between factor) 
    # For an all within design, this is total N
    # For a 2b*2b design, this is the number of people in each between condition, so in each of 2*2 = 4 groups 
    
    n<-ANOVA_design$n
    
    # specify population means for each condition (so 2 values for 2b design, 6 for 2b*3w, etc) 
    mu = ANOVA_design$mu # population means - should match up with the design
    
    sd <- ANOVA_design$sd #population standard deviation (currently assumes equal variances)
    r <- ANOVA_design$r # correlation between within factors (currently only 1 value can be entered)
    
    #indicate which adjustment for multiple comparisons you want to use (e.g., "holm")
    p_adjust <- ANOVA_design$p_adjust
    
    # how many studies should be simulated? 100.000 is very accurate, 10.000 reasonable accurate, 10.000 somewhat accurate
    nsims = nsims
    
    
    ###############
    # 2. Create Dataframe based on Design ----
    ###############
    
    #Count number of factors in design
    factors <- ANOVA_design$factors
    
    #Specify within/between factors in design: Factors that are within are 1, between 0
    design <- ANOVA_design$design
    
    sigmatrix <- ANOVA_design$sig
    
    #Create the data frame. This will be re-used in the simulation (y variable is overwritten) but created only once to save time in the simulation
    df <- ANOVA_design$df
    
    ###############
    # 3. Specify factors for formula ----
    ###############
    
    frml1 <- ANOVA_design$frml1 
    frml2 <- ANOVA_design$frml2
    
    aov_result<- suppressMessages({aov_car(frml1, #here we use frml1 to enter fromula 1 as designed above on the basis of the design 
                                           data=df,
                                           anova_table = list(es = "pes", p_adjust_method = p_adjust)) }) #This reports PES not GES
    
    # pairwise comparisons
    pc <- suppressMessages({pairs(emmeans(aov_result, frml2), adjust = p_adjust) })
    
    ############################################
    #Specify factors for formula ###############
    design_list <- ANOVA_design$design_list
    
    ###############
    # 5. Set up dataframe for simulation results
    ###############
    
    #How many possible planned comparisons are there (to store p and es)
    possible_pc <- (((prod(as.numeric(strsplit(string, "\\D+")[[1]])))^2)-prod(as.numeric(strsplit(string, "\\D+")[[1]])))/2
    
    #create empty dataframe to store simulation results
    #number of columns if for ANOVA results and planned comparisons, times 2 (p and es)
    sim_data <- as.data.frame(matrix(ncol = 2*(2^factors-1)+2*possible_pc, nrow = nsims))
    
    #Dynamically create names for the data we will store
    names(sim_data) = c(paste("anova_",
                              rownames(aov_result$anova_table), 
                              sep=""), 
                        paste("anova_es_", 
                              rownames(aov_result$anova_table), 
                              sep=""), 
                        paste("paired_comparison_", 
                              pc@grid[["contrast"]], 
                              sep=""), 
                        paste("d_", 
                              pc@grid[["contrast"]], 
                              sep=""))
    
    
    ###############
    # 7. Start Simulation ----
    ###############
    withProgress(message = 'Running simulations', value = 0, {
      for(i in 1:nsims){ #for each simulated experiment
        incProgress(1/nsims, detail = paste("Now running simulation", i, "out of",nsims,"simulations"))
        #We simulate a new y variable, melt it in long format, and add it to the df (surpressing messages)
        df$y<-suppressMessages({melt(as.data.frame(rmvnorm(n=n,
                                                           mean=mu,
                                                           sigma=sigmatrix)))$value
        })
        
        # We perform the ANOVA using AFEX
        aov_result<-suppressMessages({aov_car(frml1, #here we use frml1 to enter fromula 1 as designed above on the basis of the design 
                                              data=df,
                                              anova_table = list(es = "pes", p_adjust_method = p_adjust))}) #This reports PES not GES
        # pairwise comparisons
        pc <- suppressMessages({pairs(emmeans(aov_result, frml2), adjust = p_adjust)})
        # store p-values and effect sizes for calculations and plots.
        sim_data[i,] <- c(aov_result$anova_table[[6]], #p-value for ANOVA
                          aov_result$anova_table[[5]], #partial eta squared
                          as.data.frame(summary(pc))$p.value, #p-values for paired comparisons
                          ifelse(as.data.frame(summary(pc))$df < n, #if df < n (means within factor)
                                 as.data.frame(summary(pc))$t.ratio/sqrt(n), #Cohen's dz for within
                                 (2 * as.data.frame(summary(pc))$t.ratio)/sqrt(2*n))) #Cohen's d for between
      }
    })#close withProgress
    
    ############################################
    #End Simulation              ###############
    
    
    ###############
    # 8. Plot Results ----
    ###############
    
    # melt the data into a long format for plots in ggplot2
    
    plotData <- suppressMessages({melt(sim_data[1:(2^factors-1)], value.name = 'p')})
    
    SalientLineColor<-"#535353"
    LineColor<-"#D0D0D0"
    BackgroundColor<-"#F0F0F0"
    
    # plot each of the p-value distributions 
    options(scipen = 999) # 'turn off' scientific notation
    plt1 = ggplot(plotData, aes(x = p)) +
      scale_x_continuous(breaks=seq(0, 1, by = .1),
                         labels=seq(0, 1, by = .1)) +
      geom_histogram(colour="#535353", fill="#84D5F0", breaks=seq(0, 1, by = .01)) +
      geom_vline(xintercept = alpha, colour='red') +
      facet_grid(variable ~ .) +
      labs(x = expression(p)) +
      theme_bw() + 
      theme(panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank(),panel.grid.minor.y = element_blank()) + 
      theme(panel.background=element_rect(fill=BackgroundColor)) +
      theme(plot.background=element_rect(fill=BackgroundColor)) +
      theme(panel.border=element_rect(colour=BackgroundColor)) + 
      theme(panel.grid.major=element_line(colour=LineColor,size=.75)) + 
      theme(plot.title=element_text(face="bold",colour=SalientLineColor, vjust=2, size=20)) + 
      theme(axis.text.x=element_text(size=10,colour=SalientLineColor, face="bold")) +
      theme(axis.text.y=element_text(size=10,colour=SalientLineColor, face="bold")) +
      theme(axis.title.y=element_text(size=12,colour=SalientLineColor,face="bold", vjust=2)) +
      theme(axis.title.x=element_text(size=12,colour=SalientLineColor,face="bold", vjust=0)) + 
      theme(axis.ticks.x=element_line(colour=SalientLineColor, size=2)) +
      theme(axis.ticks.y=element_line(colour=BackgroundColor)) +
      theme(axis.line = element_line()) +
      theme(axis.line.x=element_line(size=1.2,colour=SalientLineColor)) +
      theme(axis.line.y=element_line(colour=BackgroundColor)) + 
      theme(plot.margin = unit(c(1,1,1,1), "cm"))
    
    
    ###############
    # 9. Sumary of power and effect sizes of main effects and contrasts ----
    ###############
    
    #Main effects and interactions from the ANOVA
    power = as.data.frame(apply(as.matrix(sim_data[(1:(2^factors-1))]), 2, 
                                function(x) round(mean(ifelse(x < alpha, 1, 0) * 100),3)))
    es = as.data.frame(apply(as.matrix(sim_data[((2^factors):(2*(2^factors-1)))]), 2, 
                             function(x) round(median(x),3)))
    
    main_results <- data.frame(power,es)
    names(main_results) = c("power","effect size")
    main_results
    
    #Data summary for contrasts
    power_paired = as.data.frame(apply(as.matrix(sim_data[(2*(2^factors-1)+1):(2*(2^factors-1)+possible_pc)]), 2, 
                                       function(x) round(mean(ifelse(x < alpha, 1, 0) * 100),2)))
    es_paired = as.data.frame(apply(as.matrix(sim_data[(2*(2^factors-1)+possible_pc+1):(2*(2^factors-1)+2*possible_pc)]), 2, 
                                    function(x) round(mean(x),2)))
    
    
    pc_results <- data.frame(power_paired,es_paired)
    names(pc_results) = c("power","effect size")
    pc_results
    
   
    
    # Return results in list()
    invisible(list(sim_data = sim_data,
                   main_results = main_results,
                   pc_results = pc_results,
                   plot1 = plt1))
    
  }
  
  #Create set of reactive values
  values <- reactiveValues(design_result=0, power_result=0)
  
  #Produce ANOVA design
  observeEvent(input$designBut, { values$design_result <- ANOVA_design(string = as.character(input$design),
                                                                       n = as.numeric(input$sample_size), 
                                                                       mu = as.numeric(unlist(strsplit(input$mu, ","))), 
                                                                       labelnames = as.vector(unlist(strsplit(input$labelnames, ","))), 
                                                                       sd = as.numeric(input$sd), 
                                                                       r= as.numeric(input$r), 
                                                                       p_adjust = as.character(input$p_adjust))
  })
  
  
  #Output text for ANOVA design
  output$DESIGN <- renderText({
    req(input$designBut)
    
    paste("The design is set as", values$design_result$string, 
          " 
          ", 
          "Model formula: ", deparse(values$design_result$frml1), 
          " 
          ",
          "Sample size per cell n = ", values$design_result$n, 
          " 
          ",
          "Adjustment for multiple comparisons: ", values$design_result$p_adjust)
    
  })
  
  #Output of correlation and standard deviation matrix
  output$corMat <- renderTable(colnames = FALSE, 
                               caption = "Matrix of Standard Deviation and Correlations",
                               caption.placement = getOption("xtable.caption.placement", "top"),
                               {
                                 req(input$designBut)
                                 values$design_result$sigmatrix
                                 
                               })
  #Output plot of the design
  output$plot <- renderPlot({
    req(input$designBut)
    values$design_result$meansplot})
  
  
  
  #Run simulation as an email
  
  observeEvent(input$mailButton,{
    isolate({
      
      values$power_result <-ANOVA_power(values$design_result, 
                                        alpha = input$sig, 
                                        nsims = input$nsims)
      values$anova_power <-  qplot(1:10, 1:10, geom = "blank") + theme_bw() + theme(line = element_blank(), text = element_blank()) +
        annotation_custom(grob = tableGrob(values$power_result$main_results))
  
      values$pc_power <-  qplot(1:10, 1:10, geom = "blank") + theme_bw() + theme(line = element_blank(), text = element_blank()) +
        annotation_custom(grob = tableGrob(values$power_result$pc_results))
         
      #values$pc_power <- knitr::kable(values$power_result$pc_results)
      
      values$from <- sprintf("<sendmailR@\\%s>", Sys.info()[4])
      values$body <- list("Attached are the results from ANOVA simulation app. Thanks for using our app - Aaron Caldwell & Daniel Lakens",
                          paste(" 
                                ",
                                "The design is set as", values$design_result$string, 
                                " 
                                ", 
                                "Model formula: ", deparse(values$design_result$frml1), 
                                " 
                                ",
                                "Sample size per cell n = ", values$design_result$n, 
                                " 
                                ",
                                "Adjustment for multiple comparisons: ", values$design_result$p_adjust), 
                          mime_part(values$anova_power), mime_part(values$pc_power),
                          mime_part(values$power_result$plot1), mime_part(values$design_result$meansplot))
      sendmail(values$from, input$to, input$sub, values$body,
               control=list(smtpServer="ASPMX.L.GOOGLE.COM"))
    })
  })
  
  
  #Runs simulation and saves result as reactive value
  observeEvent(input$sim, {values$power_result <-ANOVA_power(values$design_result, 
                                                             alpha = input$sig, 
                                                             nsims = input$nsims)
  
  
  })
  
  #Table output of ANOVA level effects; rownames needed
  output$tableMain <-  renderTable({
    req(input$sim)
    values$power_result$main_results},
    rownames = TRUE)
  
  #Table output of pairwise comparisons; rownames needed
  output$tablePC <-  renderTable({
    req(input$sim)
    values$power_result$pc_result},
    rownames = TRUE)
  
  
}

shinyApp(ui, server)