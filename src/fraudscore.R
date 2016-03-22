#
# This function is called via the RApache module (mod_R) to handle incoming webservice requests
#

notin <- function(x, y) x[! x %in% y]

normalizeRulecodeNames <- function(x) {
    
}

fraudscore.app <- function(env)
{
    request <- Request$new(env)
    status = "Error"
    error = "Unspecified"
    name = "Unspecified"
    version = "Unspecified"
    date = "Unspecified"
    txnid = "Unspecified"
    fraudscore = -999
    httpstatus = 200

    # Model selection: <base>/<model>/<model.version>
    path = unlist(strsplit(request$path(), split="/"))
    if (length(path) >= 4) {

        # Figure out model key
        model.name = path[length(path)-1]
        model.version = path[length(path)]
        flog.info("[%d] Request for model %s, version %s",
                   Sys.getpid(), model.name, model.version)
        # Retrieve names model
        model.key <- paste0(model.name, '__', model.version)
        model <- models[[model.key]]
        
        if ( ! is.null(model)) {
            
            # Rule codes
            if (request$post()) {
                txnid = POST['transaction_id']
                flog.debug("[%d][%s] Received request with POST parameters: %s", Sys.getpid(), txnid, paste(names(POST), collapse=','))
                flog.info("[%d][%s] Using model %s, version %s", Sys.getpid(), txnid, model$name, model$version)

                # Normalize parameters for kabbage__20140711
                if (model.key=='kabbage__20140711') {
                    flog.info("[%d][%s] Normalizing parameter names for model kabbage__20140711", Sys.getpid(), txnid)
                    names(POST) <- gsub("BOVAL", "BOSSVAL", names(POST))
                }
            
                # Filter out unused parameters
                features <- POST[intersect(model$var.names, names(POST))]
                if (length(features > 0)) {

                    flog.debug("[%d][%s] Using prediction features: %s", Sys.getpid(), txnid, paste(names(features), collapse=','))
                    rc <- data.frame(features, stringsAsFactors=FALSE)
                
                    flog.debug("[%d][%s] Convert 'NA' to real NAs", Sys.getpid(), txnid)
                    rc[rc=='NA'] <- NA
                    
                    flog.debug("[%d][%s] Adding missing predictors", Sys.getpid(), txnid)
                    mis.predictors <- notin(model$var.names, colnames(rc))
                    rc[, mis.predictors] <- NA
                
                    flog.info("[%d][%s] Predicting fraudscore", Sys.getpid(), txnid)
                    for (n in names(rc)) { if ( ! n %in% c('country', 'TLD')) { rc[n] <- as.numeric(rc[n]) }}
                    if ('country' %in% names(rc)) { rc$country <- as.factor(rc$country) }
                    if ('TLD' %in% names(rc)) { rc$TLD <- as.factor(rc$TLD) }
                    #for (n in names(rc)) { flog.debug(paste0(n, " : ", rc[n][1], " : ", class(rc[n][[1]]))) }
                    trees <- ifelse(is.null(model$best),model$n.trees,model$best)
                    fraudscore <- gbm::predict.gbm(model,
                                                   newdata = rc,
                                                   type = "response",
                                                   n.trees = trees)
                    status = 'Ok'
                    error = ''
                    name = model$name
                    version = model$version
                    date = model$date
                }
                else {
                    error =  sprintf("No usable POST parameters received.")
                    flog.error("[%d][%s] %s", Sys.getpid(), txnid, error)
                    httpstatus = 400
                }
            }
            else {
                error =  sprintf("Request missing POST parameters.")
                flog.error("[%d][%s] %s", Sys.getpid(), txnid, error)
                httpstatus = 400
            }
        }
        else {
            error =  sprintf("Requested model %s does not exist", model.key)
            flog.error("[%d][%s] %s", Sys.getpid(), txnid, error)
            httpstatus = 400
        }
    }
    else {
        error = sprintf("Missing PATH parameter(s): <base>/<model>/<model.version>")
        flog.error("[%d][%s] %s", Sys.getpid(), txnid, error)
        httpstatus = 400
    }

    # Return result
    result <- list(fraudscore = fraudscore,
                   status = status,
                   error = error,
                   name = name,
                   version = version,
                   date = date)
    resultJson = rjson::toJSON(result)
    flog.info("[%d][%s] Sending response: %s", Sys.getpid(), txnid, rjson::toJSON(result))
    response <- Response$new()
    response$status <- httpstatus
    response$header('Content-Type', 'application/json')
    response$header('Connection', 'close')
    response$write(resultJson)
    response$finish()
}
