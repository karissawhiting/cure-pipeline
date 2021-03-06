

# Single Model Runs Tidiers ---------------------------------------------

# Write a custom tidier
tidy_cure_frac <- function(x,
                      exponentiate =  FALSE, conf.level = 0.95, ...) {
  tidy <-
    tibble::tibble(
      term = x$bnm,
      estimate = x$b,
      std.error = NA,
      statistic = x$b_zvalue,
      p.value = x$b_pvalue,
      conf.low = NA,
      conf.high = NA
    )
  
  if (exponentiate == TRUE)
    tidy <- dplyr::mutate_at(tidy, vars(estimate, conf.low, conf.high), exp)
  
  tidy
}

# Write a custom tidier
tidy_surv <- function(x,
                      exponentiate =  FALSE,
                      conf.level = 0.95, ...) {
  tidy <-
    tibble::tibble(
      term = x$betanm,
      estimate = x$beta,
      std.error = NA,
      statistic = x$beta_zvalue,
      p.value = x$beta_pvalue,
      conf.low = NA,
      conf.high = NA
    )
  
  if (exponentiate == TRUE)
    tidy <- dplyr::mutate_at(tidy,
                             vars(estimate, conf.low, conf.high), exp)
  
  tidy
}

# tidy_cure() {
#   
# }

# Multiple Model Runs Tidiers ---------------------------------------------

# Write a custom tidier
multi_tidy_cure_frac <- function(multi_x,
                      exponentiate =  FALSE,
                      conf.level = 0.95, ...) {
  
  
   multi_x_tidy <- map_dfr(multi_x, ~tidy_cure_frac(.x)) 
  
   den_fun <- function(dd) {
     final_p <- dd$x[which.max(dd$y)]
     final_p
   }
   
 cure_res <- multi_x_tidy %>%
   group_by(term) %>%
   nest() %>%
   mutate(density = map(data, ~density(.x$p.value))) %>%
   mutate(final_p = map_dbl(density, ~den_fun(.x))) %>%
   mutate(est = map_dbl(data, ~.x$estimate[which(abs(.x$p.value - final_p) == min(abs(.x$p.value - final_p)))]))
 
  tidy <-
    tibble::tibble(
      term = cure_res$term,
      estimate = cure_res$est,
      std.error = NA,
      statistic = NA,
      p.value = cure_res$final_p,
      conf.low = NA,
      conf.high = NA
    )
  
  if (exponentiate == TRUE)
    tidy <- dplyr::mutate_at(tidy, vars(estimate, conf.low, conf.high), exp)
  
  tidy
}



# Write a custom tidier
multi_tidy_surv <- function(multi_x,
                      exponentiate =  FALSE,
                      conf.level = 0.95, ...) {
  
  
   multi_x_tidy <- map_dfr(multi_x, ~tidy_surv(.x)) 
  
   den_fun <- function(dd) {
     final_p <- dd$x[which.max(dd$y)]
     final_p
   }
   
 cure_res <- multi_x_tidy %>%
   group_by(term) %>%
   nest() %>%
   mutate(density = map(data, ~density(.x$p.value))) %>%
   mutate(final_p = map_dbl(density, ~den_fun(.x))) %>%
   mutate(est = map_dbl(data, ~.x$estimate[which(abs(.x$p.value - final_p) == min(abs(.x$p.value - final_p)))]))
 
  tidy <-
    tibble::tibble(
      term = cure_res$term,
      estimate = cure_res$est,
      std.error = NA,
      statistic = NA,
      p.value = cure_res$final_p,
      conf.low = NA,
      conf.high = NA
    )
  
  if (exponentiate == TRUE)
    tidy <- dplyr::mutate_at(tidy, vars(estimate, conf.low, conf.high), exp)
  
  tidy
}

multi_tidy_cure <- function(multi_x,
                      exponentiate =  FALSE,
                      conf.level = 0.95, ...) {
  
  or <- tbl_regression(multi_x, 
                       tidy_fun = multi_tidy_cure_frac,
                       exponentiate = TRUE) %>%
  modify_column_hide(column = ci)
  
  hr <- tbl_regression(multi_x, 
                       tidy_fun = multi_tidy_surv,
                       exponentiate = TRUE)%>%
  modify_column_hide(column = ci)

  
  res <-  gtsummary::tbl_merge(list(or, hr), 
                       tab_spanner = c("**Cure Fraction**",
                                       "**Survival**")) 
  
  res
  
  }


