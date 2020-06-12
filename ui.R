
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
# 

library(shiny)

shinyUI(fluidPage(

  # Application title
  titlePanel("Discretization and relative risk"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("n_groups",
                  "Number of groups in the predictor:",
                  min = 2,
                  max = 21,
                  value = 5),
      sliderInput("cor",
                  "Latent correlation:",
                  min = 0,
                  max = 1,
                  value = .5,
                  step = .05),
      numericInput("base_rate_adj",
                   "Base rate adjustment (non-linear):",
                   value = .01,
                   min = 0,
                   max = 1,
                   step = .001
                  )
    ),

    # Show a plot of the generated distribution
    mainPanel(
      HTML("<p>Relative risks are frequently used in medicine to give an intuitive understanding of how strongly some experimental condition affected some kind of dichotomous (binary) outcome. However, interpreting the effect size from relative risk number is not as simple as one might think. This visualization attempts to explain why this is so.</p>",
           "<p>Imagine we are measuring some kind of binary outcome. I will pretend it is whether a person was arrested a given year. Some people are more likely to get arrested, so one can speak of an underlying tendency, let's call it crime-proneness (assuming no bias in the justice system). This underlying trait is imperfectly related to arrests in a given year: a career criminal may fail to get arrested out of luck a given year and someone who decides to drive home from a party while intoxicated may get arrested for that despite not commiting any other criminal acts that year.</p>",
           "<p>Let's say we are interested in predicting crime and have selected some predictor, such as aggressiveness. Suppose that we measure this in some kind of numerical way, but that we don't want to use the predictor as a numeric variable. Instead we divide people into groups based on their score on the aggressiveness measure. The scatter plot in the first tab shows how this might look.</p>",
           "<p>Next up we calculate the proportion of individuals within each predictor group that were arrested that year. This gives us the absolute risk by group as shown in the second tab. If the event in question, getting arrested, is fairly rare, then absolute risks may not be very intuitive. Instead we may opt to calculate the relative risks, that is, how likely persons from the group are to be arrested compared to a particular group. One can choose which group to use as the comparison group depending on whether one wants numbers above, below or on both sides of 0. The third tab shows the relative risks for three choices of comparison group.</p>",
           "<p>The relative risks, however, are a function not just of how good our predictor is, but also of the rarity of the event and the number of groups we have decided to split people into. A common choice focus on the relative risk of the group most likely to have the event happen to them and use the lowest probability group as the comparison group. With the default settings, persons from the highest probability group are about 7 times more likely to be arrested than those from the lowest probability group. Suppose however we had some agenda to push. Let's say we want to show that aggression is not strongly related to crime. If so, then we can lower the number of groups to 2 and see that the relative risk drops to 3. If however we are interested in showing the opposite, we could increase the number of groups. If we use 21 groups, then the highest probability group is about 12.5 times more likely to be arrested. In both cases the effect size is the same however. Thus, if one compares the relative risks from the highest probability group in studies that split the predictor into different numbers of groups, the results will not be comparable and one may be mislead to believe one predictor is better than another.</p>",
           "<p>Try playing around with the settings to the left. You will see that if events are very rare, then relative risks are very large. If events are very common, then relative risks are always near 1. To be sure, the validity of the predictor also has a strong influence on the relative risks.</p>"),
      tabsetPanel(
        tabPanel("Underlying latent variables",
                 plotOutput("scatter")
        ),
        tabPanel("Absolute risk",
                 plotOutput("abs_risk")
        ),
        tabPanel("Relative risk",
                 plotOutput("rel_risk"),
                 HTML("<p>The dashed line shows relative risk of 1.</p>")
        )
      ),
      HTML("Made by <a href='http://emilkirkegaard.dk'>Emil O. W. Kirkegaard</a> using <a href='http://shiny.rstudio.com/'/>Shiny</a> for <a href='http://en.wikipedia.org/wiki/R_%28programming_language%29'>R</a>. Source code available <a href='https://github.com/Deleetdk/discretization_relative_risk'>on Github</a>.")
        
    )
    )
  )
)
