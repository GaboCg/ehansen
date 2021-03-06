#' Portafolio Eficiente
#'
#' @param er Retornos
#' @param cov.mat Matriz de varianza-covarianza
#' @param target.return Retorno objetivo
#' @param shorts Si es TRUE incluye venta corta
#'
#' @return
#' @export
#'
#' @examples
efficient_portfolio <- function(er, cov.mat, target.return, shorts=TRUE){

  call <- match.call()

  #
  # check for valid inputs
  #
  asset.names <- names(er)
  er <- as.vector(er) # assign names if none exist
  N <- length(er)
  cov.mat <- as.matrix(cov.mat)
  if(N != nrow(cov.mat))
    stop("invalid inputs")
  if(any(diag(chol(cov.mat)) <= 0))
    stop("Covariance matrix not positive definite")
  # remark: could use generalized inverse if cov.mat is positive semidefinite

  #
  # compute efficient portfolio
  #
  if(shorts==TRUE){
    ones <- rep(1, N)
    top <- cbind(2*cov.mat, er, ones)
    bot <- cbind(rbind(er, ones), matrix(0,2,2))
    A <- rbind(top, bot)
    b.target <- as.matrix(c(rep(0, N), target.return, 1))
    x <- solve(A, b.target)
    w <- x[1:N]
  } else if(shorts==FALSE){
    Dmat <- 2*cov.mat
    dvec <- rep.int(0, N)
    Amat <- cbind(rep(1,N), er, diag(1,N))
    bvec <- c(1, target.return, rep(0,N))
    result <- quadprog::solve.QP(Dmat=Dmat,dvec=dvec,Amat=Amat,bvec=bvec,meq=2)
    w <- round(result$solution, 6)
  } else {
    stop("shorts needs to be logical. For no-shorts, shorts=FALSE.")
  }

  #
  # compute portfolio expected returns and variance
  #
  names(w) <- asset.names
  er.port <- crossprod(er,w)
  sd.port <- sqrt(w %*% cov.mat %*% w)
  ans <- list("call" = call,
              "er" = as.vector(er.port),
              "sd" = as.vector(sd.port),
              "weights" = w)
  class(ans) <- "portfolio"
  return(ans)
}
