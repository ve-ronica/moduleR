#!/usr/local/bin/Rscript
#
# Test harness for prediction web service...can be run standalone without Apache httpd.
#
require(Rook)
require(rjson)
require(futile.logger)
require(methods)


RSourceOnStartup <- function(socure.base)
{
    # Load model
    flog.info("[%d] Starting prediction web service (socure.base=%s)", Sys.getpid(), socure.base)

    # Load models
    model.dir <- paste0(socure.base, '/model')
    flog.info("Loading models from directory %s", model.dir)
    for (rds in list.files(path=model.dir, pattern="\\.rds$", full.names=TRUE)) {
        model <- readRDS(rds)
        
        if (is.null(model)) {
            flog.error("[%d] Could not load model from file %s", Sys.getpid(), rds)
        }
        else {
            model.key <- paste0(model$name, '__', model$version)
            models[[model.key]] <<- model
            flog.info("[%d] Loaded model %s from file %s", Sys.getpid(), model.key, rds)
        }
    }
}
    

predict.app <- function(env)
{
    status = "Error"
    error = "Unspecified"
    name = "Unspecified"
    version = "Unspecified"
    date = "Unspecified"
    score = -1
    request <- Request$new(env)

    # Model selection: <base>/<model>/<model.version>
    path = unlist(strsplit(request$path(), split="/"))
    if (length(path) >= 4) {

        # Figure out model key
        model.name = path[length(path)-1]
        model.version = path[length(path)]
        flog.debug("Request for model %s, version %s", model.name, model.version)

        # Retrieve names model
        model.key <- paste0(model.name, '__', model.version)
        model <- models[[model.key]]
        if ( ! is.null(model)) {
            
            if (request$post()) {
                flog.debug("Received request (%s) with POST parameters: %s",
                           request$url(),
                           paste(names(request$POST()), collapse=","))

                flog.debug("Using model %s, version %s", model$name, model$version)
            
                variables <- request$POST()
                flog.debug("[%d] Using prediction features: %s", Sys.getpid(), paste(names(variables), collapse=','))
                x <- data.frame(lapply(variables, as.numeric))
                score <-predict(model, newdata = x)
                status = 'Ok'
                error = ''
                name = model$name
                version = model$version
                date = model$date
            }
            else {
                error =  sprintf("Missing POST parameters: (%s)", request$url())
                flog.error(error)
            }
        }
        else {
            error =  sprintf("Model %s does not exist", model.key)
            flog.error(error)
        }
    }
    else {
        error = sprintf("Missing PATH parameter(s): <base>/<model>/<model.version> (%s)",
            request$url())
        flog.error(error)
    }

    # Return result
    result <- list(score = score,
                   status = status,
                   error = error,
                   name = name,
                   version = version)
    resultJson = rjson::toJSON(result)
    flog.debug("Request (%s) returns: %s", request$url(), resultJson)
    response <- Response$new()
    response$header('Content-Type', 'application/json')
    response$header('Connection', 'close')
    response$write(resultJson)
    response$finish()
}



# Main
flog.threshold(DEBUG)
models <- list()
RSourceOnStartup('..')

flog.info("Starting web service")
R.server <- Rhttpd$new()
R.server$add(app = predict.app, name = "predict")
R.server$start(port=8000)
R.server$print()
R.server$browse()

while (TRUE) {
    Sys.sleep(1);
}
R.server$stop()

