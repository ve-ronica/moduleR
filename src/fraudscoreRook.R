#!/usr/bin/Rscript
#
# Test harness for fraudscore web service...can be run standalone without Apache httpd.
#
require(Rook)
require(rjson)
require(futile.logger)
require(methods)


RSourceOnStartup <- function(socure.base)
{
    # Load model
    flog.info("[%d] Starting fraudscore web service (socure.base=%s)", Sys.getpid(), socure.base)

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
    

fraudscore.app <- function(env)
{
    status = "Error"
    error = "Unspecified"
    name = "Unspecified"
    version = "Unspecified"
    date = "Unspecified"
    fraudscore = -1
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
            
            # Rule codes
            if (request$post()) {
                flog.debug("Received request (%s) with POST parameters: %s",
                           request$url(),
                           paste(names(request$POST()), collapse=","))

                flog.debug("Using model %s, version %s", model$name, model$version)
            
                # Filter out unused parameters
                features <- request$POST()[intersect(model$var.names, names(request$POST()))]
                flog.debug("[%d] Using prediction features: %s", Sys.getpid(), paste(names(features), collapse=','))
                rc <- data.frame(features, stringsAsFactors=FALSE)
                
                flog.debug("Convert 'NA' to real NAs")
                rc[rc=='NA'] <- NA
                
                flog.debug("Adding missing predictors")
                mis.predictors <- socureutils::"%w/o%"(model$var.names, colnames(rc))
                rc[, mis.predictors] <- NA
                
                flog.debug("Predicting fraudscore")
                fraudscore <- gbm::predict.gbm(model,
                                               newdata = rc,
                                               type = "response",
                                               n.trees = model$n.trees)
                
                status = 'Ok'
                error = ''
                name = model$name
                version = model$version
                date = model$date
            }
            else {
                error =  sprintf("Missing POST parameters: [rulecodes] (%s)", request$url())
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
    result <- list(fraudscore = fraudscore,
                   status = status,
                   error = error,
                   name = name,
                   version = version,
                   date = date)
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
RSourceOnStartup(getwd())

flog.info("Starting web service")
R.server <- Rhttpd$new()
R.server$add(app = fraudscore.app, name = "fraudscore")
R.server$start(port=8000)
R.server$print()
R.server$browse()

while (TRUE) {
    Sys.sleep(1);
}
R.server$stop()

# Predictor
# =========
#
# Delete environment from predictor
#
# > ls.str(attr(model$Terms, ".Environment"))
# > object.size( attr(m$Terms, ".Environment"))
# > attr(m$Terms, ".Environment") <- NULL
# > object.size( attr(m$Terms, ".Environment"))
#
#
# Testing
# =======
#
# Create test data:
#
# > x <- data.frame(replicate(length(model$var.names), sample(0:1, 10,rep=TRUE)))
# > names(x) <- model$var.names
#
# Predict:
#
# > n.trees <- gbm.perf(model$mod, method = "test", plot.it = FALSE)
# > gbm::predict.gbm(m, newdata=x, type='response', n.trees=n.trees)
#
