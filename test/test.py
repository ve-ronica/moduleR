#!/usr/bin/python2.7

import logging
import csv
import argparse
import requests
import sys
import os
import ConfigParser

# Defaults
__ini = '~/.environment.ini'
default_input = "test.csv"
default_environment = 'dev'
default_model = 'generic'
default_version = 1

# Set up logging
root = logging.getLogger()
if root.handlers:
    for handler in root.handlers:
        root.removeHandler(handler)
logging.basicConfig(format='%(asctime)s [%(threadName)s] %(levelname)s %(message)s',level=logging.DEBUG)

        

def dump(obj):
  for attr in dir(obj):
    print "obj.%s = %s" % (attr, getattr(obj, attr))  
    
#----------------------------------------
# Main
#----------------------------------------
parser = argparse.ArgumentParser("Fraudscore webservice test")
parser.add_argument("-i", "--input", required=False, type=str, default=default_input,
                    help="Data input file. Default %s" % default_input)
parser.add_argument("-e", "--environment", required=False, type=str, default=default_environment, help="Test environment. Default %s" % default_environment)
parser.add_argument("-m", "--model", required=False, type=str, default=default_model, help="Model name. Default %s" % default_model)
parser.add_argument("-v", "--version", required=False, type=str, default=default_version, help="Model version. Default %s" % default_version)

args = parser.parse_args()
input_file = args.input
environment = args.environment
model = args.model
version = args.version

# Read environment configuration 
try:
    __ini = os.path.expanduser(__ini)
    logging.info("Reading configuration from %s" % __ini)
    config = ConfigParser.ConfigParser()
    config.read(__ini)
    url = config.get(environment, 'fraudscore_url')
except Exception as e:
    logging.error("Problem reading configuration: %s" % e)
    exit(1)

url = "%s/%s/%s" % (url, model, version)
with open(input_file, 'r') as f:
    count = 0
    csvreader = csv.DictReader(f)
    for params in csvreader:
        try:
            logging.debug("Getting fraudscore for customeruserid %s", (params['customeruserid']))
            resp = requests.post(url, data=params)
            logging.debug("Received response from URL %s in %s: %s", resp.url, resp.elapsed, resp.text)
        except Exception as ex:
            logging.error("Unexpected error processing record: %s ==> %s" % (params, ex))
            break




