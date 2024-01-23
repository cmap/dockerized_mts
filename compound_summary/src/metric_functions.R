library(tidyverse)
library(magrittr)
library(useful)

# auxilary functions ----
skewness<-function(x, finite=TRUE){
  n=length(x)
  S=(1/n)*sum((x-mean(x))^3)/(((1/n)*sum((x-mean(x))^2))^1.5)
  if(finite==FALSE){
    S=S
  }else{
    S=S*(sqrt(n*(n-1)))/(n-2)
  }
  return(S)
}
kurtosis<-function(x, finite){
  n=length(x)
  K=(1/n)*sum((x-mean(x))^4)/(((1/n)*sum((x-mean(x))^2))^2) - 3
  if(finite==FALSE){
    K=K
  }
  else{
    K=((n-1)*((n+1)*K - 3*(n-1))/((n-2)*(n-3))) +3
  }
  return(K)
}
bimodality_coefficient<-function(x, finite=TRUE,...){
  if(finite==TRUE){
    G=skewness(x,finite)
    sample.excess.kurtosis=kurtosis(x,finite)
    K=sample.excess.kurtosis
    n=length(x)
    B=((G^2)+1)/(K+ ((3*((n-1)^2))/((n-2)*(n-3))))
  }
  else{
    G=skewness(x,FALSE)
    K=kurtosis(x,FALSE)
    B=((G^2)+1)/(K)
  }
  return(B)
}

