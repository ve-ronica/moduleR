#
# This function is called via the RApache module (mod_R) to handle incoming webservice requests
#

notin <- function(x, y) x[! x %in% y]

normalizeRulecodeNames <- function(x) {
    
}

predict.app <- function(env)
{
    request <- Request$new(env)
    status = "Error"
    error = "Unspecified"
    name = "Unspecified"
    version = "Unspecified"
    date = "Unspecified"
    score = -999
    httpstatus = 200

    # Model selection: <base>/<model>/<model.version>
    path = unlist(strsplit(request$path(), split="/"))
    if (length(path) >= 4) {

        # Figure out model key
        model.name = path[length(path)-1]
        model.version = path[length(path)]
        flog.info("[%d] Request for model %s, version %s", Sys.getpid(), model.name, model.version)
        
        # Retrieve names model
        model.key <- paste0(model.name, '__', model.version)
        model <- models[[model.key]]
        
        if ( ! is.null(model)) {
            
            # Rule codes
            if (request$post()) {
                flog.info("[%d] Received request with POST parameters: %s", Sys.getpid(), paste(names(POST), collapse=','))
                flog.info("[%d] Using model %s, version %s", Sys.getpid(), model$name, model$version)
                # Grab inputs from POST parameters
                variables <- POST
                if (length(variables > 0)) {

                    flog.info("[%d] Using prediction features: %s", Sys.getpid(), paste(names(variables), collapse=','))
                    #rc <- data.frame(features, stringsAsFactors=FALSE)
                    x <- data.frame(lapply(variables, as.numeric))

                    score <- predict(model, newdata = x)
                    status = 'Ok'
                    error = ''
                    name = model$name
                    version = model$version
                    date = model$date
                }
                else {
                    error =  sprintf("No usable POST parameters received.")
                    flog.error("[%d] %s", Sys.getpid(), error)
                    httpstatus = 400
                }
            }
            else {
                error =  sprintf("Request missing POST parameters.")
                flog.error("[%d] %s", Sys.getpid(), error)
                httpstatus = 400
            }
        }
        else {
            error =  sprintf("Requested model %s does not exist", model.key)
            flog.error("[%d] %s", Sys.getpid(), error)
            httpstatus = 400
        }
    }
    else {
        error = sprintf("Missing PATH parameter(s): <base>/<model>/<model.version>")
        flog.error("[%d] %s", Sys.getpid(), error)
        httpstatus = 400
    }

    # Return result
    result <- list(score = score,
                   status = status,
                   error = error,
                   name = name,
                   version = version,
                   date = date)
    resultJson = rjson::toJSON(result)
    flog.info("[%d] Sending response: %s", Sys.getpid(), rjson::toJSON(result))
    response <- Response$new()
    response$status <- httpstatus
    response$header('Content-Type', 'application/json')
    response$header('Connection', 'close')
    response$write(resultJson)
    response$finish()
}
