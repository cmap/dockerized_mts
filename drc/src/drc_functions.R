# Helper functions for the initial processing step of the MTS pipeline

#---- Load Packages ----
library(tidyverse)
library(magrittr)
library(data.table)
library(dr4pl)
library(drc)
library(readr)
library(stats)
library(reshape2)
library(argparse)
library(splitstackshape)

#---- Dose-Response Parameters ----
# area under curve given dose-response parameters
compute_auc <- function(l, u, ec50, h, md, MD) {
  f1 = function(x) pmax(pmin((l + (u - l)/(1 + (2^x/ec50)^h)), 1, na.rm = T), 0, na.rm = T)
  return(tryCatch(integrate(f1, log2(md), log2(MD))$value/(log2(MD/md)),
                  error = function(e) {print(e); NA}))
}

# log IC50 from given dose-response parameters
compute_log_ic50 <- function(l, u, ec50, h, md, MD) {
  if((l >= 0.5) | (u <= 0.5)) {
    return(NA)
  } else {
    f1 = function(x) (l + (u - l)/(1 + (2^x/ec50)^h) - 0.5)
    return(tryCatch(uniroot(f1, c(log2(md), log2(MD)))$root,
                    error = function(x) NA))
  }
}


compute_MSE_MAD <- function(LFC,  UL, LL,  Slope, Inflection,
                            FC_column="FC", dose_column="dose") {
    mse_compute <- LFC %>% 
        dplyr::mutate(FC.pred = UL  + (LL -UL )/(1 + (.[[dose_column]]/Inflection)^Slope) ) %>% 
        dplyr::mutate(squared_deviation = (.[[FC_column]]-FC.pred)^2, abs_deviation = abs(.[[FC_column]]-FC.pred)) %>%
        dplyr::summarise(mse = mean(squared_deviation), mad= mean(abs_deviation))
    return (mse_compute)
}


get_best_fit <- function(LFC_filtered, dose_var,
                         UL_low=0.8, UL_up=1.001, slope_decreasing=TRUE){
    
    var_data <- LFC_filtered$FC %>% var()
    all_fits.df <- fit_4param_drc(LFC_filtered, dose_var,  var_data, 
                                  UL_low, UL_up, slope_decreasing)
    
    if (nrow(all_fits.df)>0){
        res.df <- all_fits.df[which.max(all_fits.df$frac_var_explained),]
        
        if (res.df$frac_var_explained>0.05){
            res.df %<>% add_column(successful_fit=TRUE)
        }
        else{
            res.df %<>% add_column(successful_fit=FALSE)
        }
    }else{
        res.df  <- data.frame(successful_fit=FALSE)
    }
    
    return (res.df)
}

fit_4param_drc <- function(LFC_filtered, dose_var,  var_data, 
                           UL_low=0.8, UL_up=1.001, slope_decreasing=TRUE) {
    # UL low is the lowerbound of UL we pass to the optimizer and UL_up is the upper bound of UL that we pass to the optimizer
    results.df <- data.frame("fit_name"=character(),"Lower_Limit"=double(),
                             "Upper_Limit"=double(), 
                             "Slope"=double(),
                             "Inflection"=double(), 
                             "MSE"=double(), "MAD" =double(),
                             "frac_var_explained"=double(),
                             "Input_Parameters"=character())
    
    if (slope_decreasing){slope_bound <- 0
    }else{slope_bound <- Inf}
    
    ### constrained DRC doesn't fit nearly as well as unconstrained DRC.
    drc_model<- tryCatch(drc::drm(as.formula(paste("FC ~ ", dose_var)), data=LFC_filtered, 
                                  fct=LL.4(names = c("Slope", "Lower Limit", "Upper Limit", "ED50")),
                                  lowerl = c(-slope_bound,0.0, UL_low, -Inf),upperl = c(Inf,1.0,UL_up, Inf)),
                         error= function(e){print (e); return(list(convergence=FALSE, error=TRUE,
                                                                   fit=list(convergence=FALSE)
                         ))})
    
    if (drc_model$fit$convergence){
        
        
        # "slope" in drc package is -ve of slope in dr4pl package and so -ve sign needs to be put in here.
        mse_df <- compute_MSE_MAD(LFC_filtered, as.numeric(drc_model$coefficients [[3]]), as.numeric(drc_model$coefficients [[2]]),
                                  -as.numeric(drc_model$coefficients [[1]]), as.numeric(drc_model$coefficients [[4]]),
                                  "FC", dose_var)
        
        # print (mse_df$mse)
        results.df %<>% 
            dplyr::add_row("fit_name"="drc_drm","Lower_Limit"=as.numeric(drc_model$coefficients [[2]]),
                           "Upper_Limit"=as.numeric(drc_model$coefficients [[3]]), 
                           "Slope"=-as.numeric(drc_model$coefficients [[1]]),
                           "Inflection"=as.numeric(drc_model$coefficients [[4]]), 
                           "MSE"=mse_df$mse, "MAD" =mse_df$mad, "frac_var_explained"=1-mse_df$mse/var_data, 
                           "Input_Parameters"="constrained-drc")
    }
    

    dr4pl_model2 <- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                   init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.005),
                                   method.init = "logistic",
                                   lowerl = c(UL_low, -Inf, -Inf, 0),
                                   upperl = c(UL_up, Inf, slope_bound, 1.0)),
                             error= function(e){print (e); return(list(convergence=FALSE, error=TRUE))})
    if (dr4pl_model2$convergence){
        mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_model2$parameters[[1]], dr4pl_model2$parameters[[4]],
                                  dr4pl_model2$parameters[[3]], dr4pl_model2$parameters [[2]],
                                  "FC", dose_var)
        results.df %<>% 
            dplyr::add_row("fit_name"="dr4pl_model2","Lower_Limit"=as.numeric(dr4pl_model2$parameters [[4]]),
                           "Upper_Limit"=as.numeric(dr4pl_model2$parameters [[1]]), 
                           "Slope"=as.numeric(dr4pl_model2$parameters [[3]]),
                           "Inflection"=as.numeric(dr4pl_model2$parameters [[2]]), "MSE"=mse_df$mse, "MAD" =mse_df$mad, "frac_var_explained"=1-mse_df$mse/var_data,  
                           "Input_Parameters"="constrained|init_logistic")
    }

    
    dr4pl_model4 <- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                   init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.01),
                                   method.init = "Mead",
                                   lowerl = c(UL_low, -Inf, -Inf, 0),
                                   upperl = c(UL_up, Inf, slope_bound, 1.0),
                                   method.optim="Nelder-Mead"),
                             error= function(e){print (e); return(list(convergence=FALSE, error=TRUE))})
    if (dr4pl_model4$convergence){
        mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_model4$parameters[[1]], dr4pl_model4$parameters[[4]],
                                  dr4pl_model4$parameters[[3]], dr4pl_model4$parameters [[2]],
                                  "FC", dose_var)
        
        results.df %<>% 
            dplyr::add_row("fit_name"="dr4pl_model4","Lower_Limit"=as.numeric(dr4pl_model4$parameters [[4]]),
                           "Upper_Limit"=as.numeric(dr4pl_model4$parameters [[1]]), 
                           "Slope"=as.numeric(dr4pl_model4$parameters [[3]]),
                           "Inflection"=as.numeric(dr4pl_model4$parameters [[2]]), "MSE"=mse_df$mse, "MAD" =mse_df$mad, "frac_var_explained"=1-mse_df$mse/var_data,  
                           "Input_Parameters"="constrained|init_Mead|optim_Nelder-Mead")
    }
    
    
    dr4pl_model7 <- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                   init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.01),
                                   method.init = "logistic",
                                   lowerl = c(UL_low, -Inf, -Inf, 0),
                                   upperl = c(UL_up, Inf, slope_bound, 1.0),
                                   method.optim="BFGS"),
                             error= function(e){print (e); return(list(convergence=FALSE, error=TRUE))})
    if (dr4pl_model7$convergence){
        mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_model7$parameters[[1]], dr4pl_model7$parameters[[4]],
                                  dr4pl_model7$parameters[[3]], dr4pl_model7$parameters [[2]],
                                  "FC", dose_var)
        
        results.df %<>% 
            dplyr::add_row("fit_name"="dr4pl_model7","Lower_Limit"=as.numeric(dr4pl_model7$parameters [[4]]),
                           "Upper_Limit"=as.numeric(dr4pl_model7$parameters [[1]]), 
                           "Slope"=as.numeric(dr4pl_model7$parameters [[3]]),
                           "Inflection"=as.numeric(dr4pl_model7$parameters [[2]]), "MSE"=mse_df$mse, "MAD" =mse_df$mad, "frac_var_explained"=1-mse_df$mse/var_data,  
                           "Input_Parameters"="constrained|init_logistic|optim_BFGS")
    }   
    
    dr4pl_model8<- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                  init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.01),
                                  method.robust="Huber",
                                  lowerl = c(UL_low, -Inf, -Inf, 0),
                                  upperl = c(UL_up, Inf, slope_bound, 1.0)),
                            error= function(e){print (e); return(list(convergence=FALSE, error=TRUE))})
    if (dr4pl_model8$convergence){
        mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_model8$parameters[[1]], dr4pl_model8$parameters[[4]],
                                  dr4pl_model8$parameters[[3]], dr4pl_model8$parameters [[2]],
                                  "FC", dose_var)
        
        results.df %<>% 
            dplyr::add_row("fit_name"="dr4pl_model8","Lower_Limit"=as.numeric(dr4pl_model8$parameters [[4]]),
                           "Upper_Limit"=as.numeric(dr4pl_model8$parameters [[1]]), 
                           "Slope"=as.numeric(dr4pl_model8$parameters [[3]]),
                           "Inflection"=as.numeric(dr4pl_model8$parameters [[2]]), "MSE"=mse_df$mse, "MAD" =mse_df$mad, "frac_var_explained"=1-mse_df$mse/var_data,  
                           "Input_Parameters"="constrained|loss_Huber")
    }

    return (results.df)
}


