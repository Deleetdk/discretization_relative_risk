
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

#functions
#returns the beta of the error variance
get_error = function(beta) {
  beta_var = beta^2 #sq. beta to get % var accounted for
  remain_var = 1 - beta_var #subtract from 1 to get % remain var
  remain_beta = sqrt(remain_var) #sqrt to get the beta for the remainder
  return(remain_beta)
}

#gets both the probability for event and non-event
get_both_probs = function(x) {
  return(c(x, 1 - x))
}

library(shiny)
library(plyr)
library(ggplot2)
library(reshape)
library(stringr)
library(grid)

shinyServer(function(input, output) {
  
  #reactive data, case-level
  r_d = reactive({
    #reproducible
    set.seed(1)
    n = 1e4
    
    #make latent pred var
    d = data.frame(pred_con = rnorm(n))
    
    #make discrete predictor
    d$pred_discrete = cut(d$pred_con, quantile(d$pred_con, seq(0, 1, length.out = input$n_groups + 1)), labels = F, include.lowest = T)
    d$pred_discrete = as.factor(d$pred_discrete) #as factor
    
    #make latent outcome var
    d$out_con = d$pred_con * input$cor + get_error(input$cor) * rnorm(n)
    
    #make binary outcome var
    #modify add in the 
    x_adjust = qnorm(input$base_rate_adj) #converts the z score adjustment to get the given probability
    x_pnorm = pnorm(d$out_con + x_adjust) #adds the z score
    
    #roll the dice and get results
    x_binary = numeric()
    for (idx in seq_along(x_pnorm)) {
      x_binary[idx] = sample(x = 1:0, #sample from 0 and 1
                             size = 1, #get 1 sample
                             prob = get_both_probs(x_pnorm[idx]) #with these probabilities
      )
    }
    
    #save to d
    d$out_binary = x_binary
    
    return(d)
  })
  
  r_base_rate = reactive({
    #fetch d
    d = r_d()
    
    #return baseline
    return(mean(d$out_binary))
  })
  
  #reactive data, group-level
  r_d2 = reactive({
    #fetch d
    d = r_d()
    
    #proportion of true's in each category
    d2 = ddply(.data = d, .variables = .(pred_discrete),
               .fun = summarize,
               prop = mean(out_binary))
    
    #relative risks
    d2$RR_low = d2$prop / d2[1, "prop"]
    d2$RR_high = d2$prop / d2[nrow(d2), "prop"]
    central_row = floor(median(1:nrow(d2))) #get median value, round down. Otherwise if the number of groups is an even number, median will be a non-integer
    d2$RR_central = d2$prop / d2[central_row, "prop"]
    
    return(d2)
  })

  #latent correlation
  output$scatter <- renderPlot({
    #fetch data
    d = r_d()
    
    #plot
    g = ggplot(d, aes(pred_con, out_con)) + 
      geom_point(aes(color = pred_discrete)) + 
      geom_smooth(method = lm, se = F) + 
      xlab("Underlying predictor phenotype") + 
      ylab("Underlying outcome phenotype") + 
      scale_color_discrete(name = "Predictor group") +
      theme_bw()
    
    return(g)
  })
  
  #absolute risk by group
  output$abs_risk = renderPlot({
    #fetch data
    d2 = r_d2()
    base_rate = round(r_base_rate(), 3)
    
    #text grob
    geom_text(x = length(d2$pred_discrete), y = .05, label = round(r_base_rate(), 3))
    text = str_c("Base rate = ", base_rate)
    grob = grobTree(textGrob(text, x = .95,  y = .1, hjust = 1,
                             gp=gpar(col="black", fontsize=13)))
    grob_bg = grobTree(rectGrob(gp=gpar(fill="white"), x = .89, y = .1, width = .15, height = .1))
    
    #plot prop by group
    g = ggplot(d2, aes(pred_discrete, prop)) + 
      geom_bar(stat = "identity") + 
      xlab("Predictor group") + 
      ylab("Absolute risk") + 
      annotation_custom(grob_bg) + 
      annotation_custom(grob) +
      theme_bw()
    
    return(g)
  })
  
  #relative risk by group
  output$rel_risk = renderPlot({
    #fetch data
    d2 = r_d2()
    
    #to long form
    d2$prop = NULL #remove
    d3 = melt(d2)
    d3$variable = factor(d3$variable, c("RR_low", "RR_central", "RR_high"))
    
    #plot
    g = ggplot(d3, aes(pred_discrete, value)) + 
      geom_bar(aes(group = variable, fill = variable), stat = "identity", position = "dodge") + 
      xlab("Predictor group") + 
      ylab("Relative risk") + 
      geom_hline(yintercept = 1, linetype = "dashed") + 
      scale_fill_discrete(name = "Comparison\ngroup", label = c("Lowest", "Central", "Highest")) +
      theme_bw()
    
    return(g)
  })
})
