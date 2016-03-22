# This file is triggered by the RApache REvalOnStartup directive.
# REvalOnStartup takes one argument: a string containing R expressions
# to evaluate upon startup. Any number of these directives can appear
# throughout the config files, and they are evaluated in the global
# environment in the order they appear. Useful for setting options and
# loading libraries.

require(futile.logger)
require(rjson)


# Set up logging
flog.threshold(INFO)
flog.appender(appender.file('/tmp/rapache.log'))

# Load Models
models <- list()
model.dir <- paste0(socure.base, '/model')
flog.info("Loading models from directory %s", model.dir)
for (rds in list.files(path=model.dir, pattern="\\.rds$", full.names=TRUE)) {
    model <- readRDS(rds)
    
    if (is.null(model)) {
        flog.error("[%d] Could not load model from file %s", Sys.getpid(), rds)
    }
    else {
        model.key <- paste0(model$name, '__', model$version)
        models[[model.key]] <- model
        flog.info("[%d] Loaded model %s from file %s", Sys.getpid(), model.key, rds)
    }
}

flog.info("[%d] Starting web service", Sys.getpid())

