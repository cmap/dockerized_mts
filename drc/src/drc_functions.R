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

## NOTE the functions here use a sign convention for the slope parameter consistent with dr4pl package
## The data is finally saved and passed to future modules with the opposite sign convention for the slope parameter (based on drc package)
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
        dplyr::filter(is.finite(.[[FC_column]]),is.finite(.[[dose_column]]) ) %>% ## in case there are some na values accidentally passed.
        dplyr::mutate(FC.pred = UL  + (LL -UL )/(1 + (.[[dose_column]]/Inflection)^Slope) ) %>% 
        dplyr::mutate(squared_deviation = (.[[FC_column]]-FC.pred)^2, abs_deviation = abs(.[[FC_column]]-FC.pred)) %>%
        dplyr::summarise(mse = mean(squared_deviation,na.rm=T), mad= median(abs_deviation,na.rm=T))
    return (mse_compute)
}


get_best_fit <- function(LFC_filtered, dose_var,
                         UL_low=0.8, UL_up=1.01, slope_decreasing=TRUE){
    ## get best fit among different attempts at fitting, and see if this fit works sufficiently well to be reported.
    
    LFC_filtered %<>% dplyr::filter(is.finite(FC),is.finite(.[[dose_var]]) ) ## remove any NA that may appear in the data
    var_data <- LFC_filtered$FC %>% var()
    riemann_AUC <- pmin(LFC_filtered$FC,1) %>% mean() ## mean fold-change after rounding FC to 1.
    all_fits.df <- fit_4param_drc(LFC_filtered, dose_var,  var_data, 
                                  UL_low, UL_up, slope_decreasing)
    
    res.df  <- data.frame(successful_fit=FALSE, auc_riemann = riemann_AUC) ## default return value if fit is unsuccessful
    

    
    if (nrow(all_fits.df)>0){all_fits.df %<>% dplyr::filter(!is.na(frac_var_explained))} ## remove entries with NA in variance explained 

    
    if (nrow(all_fits.df)>0){
        res.df <- all_fits.df %>%
            slice_max(frac_var_explained, n = 1, with_ties = FALSE) %>%  ## return best fit. if tied, return first of the ties
            dplyr::mutate(successful_fit = TRUE, 
                          auc_riemann = as.numeric(riemann_AUC) ) ## fit has to be at least as good as predicting just the mean of the data to be called successful
    }
    
    return (res.df)
}

fit_4param_drc <- function(LFC_filtered, dose_var,  var_data, 
                                    UL_low=0.8, UL_up=1.01, slope_decreasing=TRUE) {
    #fits a number of alternate models  to the DRC and passes the results to the calling function (which chooses the best fit.)
    
    # UL low is the lowerbound of UL we pass to the optimizer and UL_up is the upper bound of UL that we pass to the optimizer
    # fomat of output will be:-
    # results.df <- data.frame("fit_name"=character(),"Lower_Limit"=double(),
    #                          "Upper_Limit"=double(), 
    #                          "Slope"=double(),
    #                          "Inflection"=double(), 
    #                          "MSE"=double(), "MAD" =double(),
    #                          "frac_var_explained"=double(),
    #                          "Input_Parameters"=character())
    
    results.df <- list(); ix = 1
    
    slope_bound <- ifelse(slope_decreasing, 1e-5, Inf)  # bound the slopes by default unless passed another option
    
    dr4pl_initL <- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                  init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.005),
                                  method.init = "logistic",
                                  lowerl = c(UL_low, -Inf, -Inf, 0),
                                  upperl = c(UL_up, Inf, slope_bound, 1.01)),
                            error= function(e){return(list(convergence=FALSE, error=TRUE))}
    )
    if (dr4pl_initL$convergence==FALSE){
      if (!is.null(dr4pl_initL$dr4pl.robust)) { 
        dr4pl_initL <- dr4pl_initL$dr4pl.robust
      }
    }
    
    if (dr4pl_initL$convergence){
        mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_initL$parameters[[1]], dr4pl_initL$parameters[[4]],
                                  dr4pl_initL$parameters[[3]], dr4pl_initL$parameters [[2]],
                                  "FC", dose_var)
        
        results.df[[ix]] <- tibble( fit_name = "dr4pl_initL", 
                                    Lower_Limit = as.numeric(dr4pl_initL$parameters [[4]]),
                                    Upper_Limit = as.numeric(dr4pl_initL$parameters [[1]]),
                                    Slope = as.numeric(dr4pl_initL$parameters [[3]]),
                                    Inflection = as.numeric(dr4pl_initL$parameters [[2]]),
                                    MSE = mse_df$mse, MAD = mse_df$mad, frac_var_explained = 1-mse_df$mse/var_data,
                                    Input_Parameters = "constrained|init_logistic")
        ix = ix + 1 
        
    }
    
    
    dr4pl_initM_optNM <- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                        init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.01),
                                        method.init = "Mead",
                                        lowerl = c(UL_low, -Inf, -Inf, 0),
                                        upperl = c(UL_up, Inf, slope_bound, 1.01),
                                        method.optim="Nelder-Mead"),
                                  error= function(e){return(list(convergence=FALSE, error=TRUE))}
    )
    if (dr4pl_initM_optNM$convergence==FALSE){
      if (!is.null(dr4pl_initM_optNM$dr4pl.robust)) { 
        dr4pl_initM_optNM <- dr4pl_initM_optNM$dr4pl.robust
      }
    }
    
    if (dr4pl_initM_optNM$convergence){
        mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_initM_optNM$parameters[[1]], dr4pl_initM_optNM$parameters[[4]],
                                  dr4pl_initM_optNM$parameters[[3]], dr4pl_initM_optNM$parameters [[2]],
                                  "FC", dose_var)
        
        results.df[[ix]] <- tibble( fit_name = "dr4pl_initM_optNM", 
                                    Lower_Limit = as.numeric(dr4pl_initM_optNM$parameters [[4]]),
                                    Upper_Limit = as.numeric(dr4pl_initM_optNM$parameters [[1]]),
                                    Slope = as.numeric(dr4pl_initM_optNM$parameters [[3]]),
                                    Inflection = as.numeric(dr4pl_initM_optNM$parameters [[2]]),
                                    MSE = mse_df$mse, MAD = mse_df$mad, frac_var_explained = 1-mse_df$mse/var_data,
                                    Input_Parameters = "constrained|init_Mead|optim_Nelder-Mead")
        ix = ix + 1 
    }
    
    
    dr4pl_initL_optB <- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                       init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.01),
                                       method.init = "logistic",
                                       lowerl = c(UL_low, -Inf, -Inf, 0),
                                       upperl = c(UL_up, Inf, slope_bound, 1.01),
                                       method.optim="BFGS"),
                                 error= function(e){return(list(convergence=FALSE, error=TRUE))}
    )
    if (dr4pl_initL_optB$convergence==FALSE){
      if (!is.null(dr4pl_initL_optB$dr4pl.robust)) { 
        dr4pl_initL_optB <- dr4pl_initL_optB$dr4pl.robust
      }
    }
    
    if (dr4pl_initL_optB$convergence){
        mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_initL_optB$parameters[[1]], dr4pl_initL_optB$parameters[[4]],
                                  dr4pl_initL_optB$parameters[[3]], dr4pl_initL_optB$parameters [[2]],
                                  "FC", dose_var)
        
        
        results.df[[ix]] <- tibble( fit_name = "dr4pl_initL_optB", 
                                    Lower_Limit = as.numeric(dr4pl_initL_optB$parameters [[4]]),
                                    Upper_Limit = as.numeric(dr4pl_initL_optB$parameters [[1]]),
                                    Slope = as.numeric(dr4pl_initL_optB$parameters [[3]]),
                                    Inflection = as.numeric(dr4pl_initL_optB$parameters [[2]]),
                                    MSE = mse_df$mse, MAD = mse_df$mad, frac_var_explained = 1-mse_df$mse/var_data,
                                    Input_Parameters = "constrained|init_logistic|optim_BFGS")
        ix = ix + 1 
        
    }
    
    dr4pl_lossHuber<- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                     init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.01),
                                     method.robust="Huber",
                                     lowerl = c(UL_low, -Inf, -Inf, 0),
                                     upperl = c(UL_up, Inf, slope_bound, 1.01)),
                               error= function(e){return(list(convergence=FALSE, error=TRUE))}
    )
    if (dr4pl_lossHuber$convergence==FALSE){
      if (!is.null(dr4pl_lossHuber$dr4pl.robust)) { 
        dr4pl_lossHuber <- dr4pl_lossHuber$dr4pl.robust
      }
    }
    
    
    if (dr4pl_lossHuber$convergence){
        mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_lossHuber$parameters[[1]], dr4pl_lossHuber$parameters[[4]],
                                  dr4pl_lossHuber$parameters[[3]], dr4pl_lossHuber$parameters [[2]],
                                  "FC", dose_var)
        
        
        results.df[[ix]] <- tibble( fit_name = "dr4pl_lossHuber", 
                                    Lower_Limit = as.numeric(dr4pl_lossHuber$parameters [[4]]),
                                    Upper_Limit = as.numeric(dr4pl_lossHuber$parameters [[1]]),
                                    Slope = as.numeric(dr4pl_lossHuber$parameters [[3]]),
                                    Inflection = as.numeric(dr4pl_lossHuber$parameters [[2]]),
                                    MSE = mse_df$mse, MAD = mse_df$mad, frac_var_explained = 1-mse_df$mse/var_data,
                                    Input_Parameters = "constrained|loss_Huber")
        ix = ix + 1 
        
    }
    
    ### add in original default drc into pipeline just to compare. ######
    dr4pl_unconstrained <- tryCatch(dr4pl(dose = LFC_filtered[[dose_var]], response = LFC_filtered$FC,
                        init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.3),
                        method.init = "logistic",
                        lowerl = c(0.99, -Inf, -Inf, 0),
                        upperl = c(1.01, Inf, Inf, 1.01)),
                  error = function(e) {print(e); return(NA)})
    
    # if it fits and doesn't converge grab robust fit
    if (!all(is.na(dr4pl_unconstrained))) {
      if (!dr4pl_unconstrained$convergence) {
        dr4pl_unconstrained <- dr4pl_unconstrained$dr4pl.robust 
      }
    }
    # get parameters
    param <- tryCatch(dr4pl_unconstrained$parameters, error = function(e) return(NA))
    if (!all(is.na(param))){
      if(as.numeric(dr4pl_unconstrained$parameters [[3]])<slope_bound){ ### while slope bound is not passed to this last optimizer, we do not accept a solution not within the bound
        mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_unconstrained$parameters[[1]], dr4pl_unconstrained$parameters[[4]],
                                  dr4pl_unconstrained$parameters[[3]], dr4pl_unconstrained$parameters [[2]],
                                  "FC", dose_var)
        results.df[[ix]] <- tibble( fit_name = "original", 
                                    Lower_Limit = as.numeric(dr4pl_unconstrained$parameters [[4]]),
                                    Upper_Limit = as.numeric(dr4pl_unconstrained$parameters [[1]]),
                                    Slope = as.numeric(dr4pl_unconstrained$parameters [[3]]),
                                    Inflection = as.numeric(dr4pl_unconstrained$parameters [[2]]),
                                    MSE = mse_df$mse, MAD = mse_df$mad, frac_var_explained = 1-mse_df$mse/var_data,
                                    Input_Parameters = "unconstrained_optim_dr4pl")
        ix = ix + 1 
      }
    }
    
    ### two additional manual ways of initializing the fit to cover all bases.
    dr4pl_initMan_optB <- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                       init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_2 = 1.1*min(LFC_filtered[[dose_var]]),
                                                                      theta_3= -.5, theta_4 = 0.01),
                                       lowerl = c(UL_low, -Inf, -Inf, 0),
                                       upperl = c(UL_up, Inf, slope_bound, 1.01),
                                       method.optim="BFGS"),
                                 error= function(e){return(list(convergence=FALSE, error=TRUE))}
    )
    if (dr4pl_initMan_optB$convergence==FALSE){
      if (!is.null(dr4pl_initMan_optB$dr4pl.robust)) { 
        dr4pl_initMan_optB <- dr4pl_initMan_optB$dr4pl.robust
      }
    }
    
    
    if (dr4pl_initMan_optB$convergence){
      mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_initMan_optB$parameters[[1]], dr4pl_initMan_optB$parameters[[4]],
                                dr4pl_initMan_optB$parameters[[3]], dr4pl_initMan_optB$parameters [[2]],
                                "FC", dose_var)
      
      
      results.df[[ix]] <- tibble( fit_name = "dr4pl_initMan_optB", 
                                  Lower_Limit = as.numeric(dr4pl_initMan_optB$parameters [[4]]),
                                  Upper_Limit = as.numeric(dr4pl_initMan_optB$parameters [[1]]),
                                  Slope = as.numeric(dr4pl_initMan_optB$parameters [[3]]),
                                  Inflection = as.numeric(dr4pl_initMan_optB$parameters [[2]]),
                                  MSE = mse_df$mse, MAD = mse_df$mad, frac_var_explained = 1-mse_df$mse/var_data,
                                  Input_Parameters = "constrained|init_Manual|optim_BFGS")
      ix = ix + 1 
    }
    
    dr4pl_initMan_optNM <- tryCatch(dr4pl(as.formula(paste("FC ~ ", dose_var)), data = LFC_filtered,
                                        init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_2 = 8*min(LFC_filtered[[dose_var]]),
                                                                       theta_3= -3, theta_4 = 0.01),
                                        lowerl = c(UL_low, -Inf, -Inf, 0),
                                        upperl = c(UL_up, Inf, slope_bound, 1.01),
                                        method.optim="Nelder-Mead"),
                                  error= function(e){return(list(convergence=FALSE, error=TRUE))}
      )
    if (dr4pl_initMan_optNM$convergence==FALSE){
      if (!is.null(dr4pl_initMan_optNM$dr4pl.robust)) { 
        dr4pl_initMan_optNM <- dr4pl_initMan_optNM$dr4pl.robust
      }
    }
    
    if (dr4pl_initMan_optNM$convergence){
      mse_df <- compute_MSE_MAD(LFC_filtered, dr4pl_initMan_optNM$parameters[[1]], dr4pl_initMan_optNM$parameters[[4]],
                                dr4pl_initMan_optNM$parameters[[3]], dr4pl_initMan_optNM$parameters [[2]],
                                "FC", dose_var)
      
      results.df[[ix]] <- tibble( fit_name = "dr4pl_initMan_optNM", 
                                  Lower_Limit = as.numeric(dr4pl_initMan_optNM$parameters [[4]]),
                                  Upper_Limit = as.numeric(dr4pl_initMan_optNM$parameters [[1]]),
                                  Slope = as.numeric(dr4pl_initMan_optNM$parameters [[3]]),
                                  Inflection = as.numeric(dr4pl_initMan_optNM$parameters [[2]]),
                                  MSE = mse_df$mse, MAD = mse_df$mad, frac_var_explained = 1-mse_df$mse/var_data,
                                  Input_Parameters = "constrained|init_Manual|optim_Nelder-Mead")
      ix = ix + 1 
    }
    
    # warning is in with Calling Handlers and error is in tryCatch
    # drc_model <-  tryCatch(withCallingHandlers(
    #   drc::drm(as.formula(paste("FC ~ ", dose_var)), data=LFC_filtered,
    #            fct=LL.4(names = c("Slope", "Lower Limit", "Upper Limit", "ED50")),
    #            lowerl = c(-slope_bound,0.0, UL_low, -Inf),upperl = c(Inf,1.01,UL_up, Inf)),
    #   warning = function (w){
    #     invokeRestart("muffleWarning")
    #   }
    # ),
    # error = function(e)
    # {
    #   return(list(convergence=FALSE, error=TRUE,fit=list(convergence=FALSE)))}
    # )
    
    # # "slope" in drc package is -ve of slope in dr4pl package
    # 
    drc_model <-  tryCatch(drc::drm(as.formula(paste("FC ~ ", dose_var)), data=LFC_filtered,
                      fct=LL.4(names = c("Slope", "Lower Limit", "Upper Limit", "ED50")),
                      lowerl = c(-slope_bound,0.0, UL_low, -Inf),upperl = c(Inf,1.01,UL_up, Inf)),
             error = function(e)
             {return(list(convergence=FALSE, error=TRUE,fit=list(convergence=FALSE)))})
    # "slope" in drc package is -ve of slope in dr4pl package


    if (drc_model$fit$convergence){

      mse_df <- compute_MSE_MAD(LFC_filtered, as.numeric(drc_model$coefficients [[3]]), as.numeric(drc_model$coefficients [[2]]),
                                -as.numeric(drc_model$coefficients [[1]]), as.numeric(drc_model$coefficients [[4]]),
                                "FC", dose_var)
      # "slope" in drc package is -ve of slope in dr4pl package and so -ve sign needs to be put in here.

      results.df[[ix]] <- tibble( fit_name = "drc_drm",
                                  Lower_Limit = as.numeric(drc_model$coefficients [[2]]),
                                  Upper_Limit = as.numeric(drc_model$coefficients [[3]]),
                                  Slope = -as.numeric(drc_model$coefficients [[1]]),
                                  Inflection = as.numeric(drc_model$coefficients [[4]]),
                                  MSE = mse_df$mse, MAD = mse_df$mad, frac_var_explained = 1-mse_df$mse/var_data,
                                  Input_Parameters = "constrained-drc")
      ix = ix + 1
    }
    
    
    return (dplyr::bind_rows(results.df))
}