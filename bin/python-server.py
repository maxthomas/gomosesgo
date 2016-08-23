#!/usr/bin/env python
import os
import sys
import threading
import subprocess
import cherrypy
import json
import simplejson
import logging
import time
import re
import xmlrpclib
import math
import pprint
from threading import Timer

afrlmt="/home/moses"

def popen(cmd):
    cmd = cmd.split()
    logger = logging.getLogger('translation_log.popen')
    logger.info("executing: %s" %(" ".join(cmd)))
    return subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)

def pclose(pipe):
    def kill_pipe():
        pipe.kill()
    t = Timer(5., kill_pipe)
    t.start()
    pipe.terminate()
    t.cancel()

def init_log(filename):
    logger = logging.getLogger('translation_log')
    logger.setLevel(logging.DEBUG)
    fh = logging.FileHandler(filename)
    fh.setLevel(logging.DEBUG)
    logformat = '%(asctime)s %(thread)d - %(filename)s:%(lineno)s: %(message)s'
    formatter = logging.Formatter(logformat)
    fh.setFormatter(formatter)
    logger.addHandler(fh)

def geometric_mean(log_probs):
    try:
        return math.exp(sum(log_probs)) ** (1./len(log_probs))
    except:
        return 0

class Filter(object):
    def __init__(self, remove_newlines=True, collapse_spaces=True):
        self.filters = []
        if remove_newlines:
            self.filters.append(self.__remove_newlines)
        if collapse_spaces:
            self.filters.append(self.__collapse_spaces)
	
    def filter(self, s):
        for f in self.filters:
            s = f(s)
        return s

    def __remove_newlines(self, s):
        s = s.replace('\r\n',' ')
        s = s.replace('\n',' ')
        return s

    def __collapse_spaces(self, s):
        s=re.sub('\s\s+', ' ', s)
	s=re.sub('\s([\',.])',r'\1',s)
	return s


def json_error(status, message, traceback, version):
    err = {"status":status, "message":message, "traceback":traceback, "version":version}
    return json.dumps(err, sort_keys=True, indent=4)

class ExternalProcessor(object):
    """ wraps an external script and does utf-8 conversions, is thread-safe """
    def __init__(self, cmd):
        self.cmd = cmd
        if self.cmd != None:
            self.proc = popen(cmd)
            self._lock = threading.Lock()

    def process(self, line):
        if self.cmd == None: return line
        u_string = u"%s\n" %line
        u_string = u_string.encode("utf-8")
        result = u_string  #fallback: return input
        with self._lock:
            self.proc.stdin.write(u_string)
            self.proc.stdin.flush()
            result = self.proc.stdout.readline()
        return result.decode("utf-8").strip()
        # should be rstrip but normalize_punctiation.perl inserts space
        # for lines starting with '('

class Root(object):

    def __init__(self, moses_home, moses_url, slang, tlang, pretty=False, verbose=0, timeout=-1): 
        
	self.filter = Filter(remove_newlines=True, collapse_spaces=True)
        self.moses_url = moses_url
	#self.recaser_url = recaser_url
        self.pretty = bool(pretty)
        self.timeout = timeout
        self.verbose = verbose

        
        tagger = ['perl',os.path.join(afrlmt, "bin", "pretag-twitter-zone.perl") , "-b", "-protected", os.path.join(afrlmt, "bin", "tag-fixed-twitter-protected-patterns")]
        tokenizer = ['perl',os.path.join(afrlmt, "bin", "moses_proc_zone.perl")]
        #tokenizer = ['perl',os.path.join(moses_home,"scripts","tokenizer","tokenizer.perl"),"-b","-X","-l",slang,'-a']
        rejoinhasher = ['perl',os.path.join(afrlmt, "bin", "rejoin-hashtags.perl")]
        detokenizer = ['perl',os.path.join(afrlmt, "bin", "detokenizer.perl"),"-b","-l",tlang]
	#detruecaser = ['perl',os.path.join(moses_home,"mosesdecoder","scripts","recaser","detruecase.perl"),"-b"]

	self._tagger = map(ExternalProcessor, [u' '.join(tagger)])
	self._tokenizer = map(ExternalProcessor, [u' '.join(tokenizer)])
 	self._detokenizer = map(ExternalProcessor, [u' '.join(detokenizer)])
        self._rejoinhasher = map(ExternalProcessor, [u' '.join(rejoinhasher)]) 
	#self._detruecaser = map(ExternalProcessor,[u' '.join(detruecaser)])

        self.tag = self._exec(self._tagger)
	self.tokenize = self._exec(self._tokenizer)
        self.rejoinhash = self._exec(self._rejoinhasher)
	self.detokenize = self._exec(self._detokenizer)
	#self.detruecase = self._exec(self._detruecaser)

    def _exec(self, procs):
        def f(line):
            for proc in procs:
                line = proc.process(line)
            return line
        return f

    def _timeout_error(self, q, location):
        errors = [{"originalquery":q, "location" : location}]
        message = "Timeout after %ss" %self.timeout
        return {"error": {"errors":errors, "code":400, "message":message}}

    def _dump_json(self, data):
        if self.pretty:
            return json.dumps(data, indent=2) + "\n"
        return json.dumps(data) + "\n"

    def _load_json(self, string):
        return json.loads(string)

    def tokenize(self, sentence):
	sentence_tokenized = self.tokenize(sentence)
	return sentence_tokenized

    def detokenize(self, sentence):
	sentence_detokenized = self.detokenize(sentence)
	return sentence_detokenized

    def _translate(self, source):
        """ wraps the actual translate call to mosesserver via XMLPRC """
        proxy = xmlrpclib.ServerProxy(self.moses_url)
        params = {"text":source}
        return proxy.translate(params)

    def _recaser(self, sentence):
	proxy=xmlrpclib.ServerProxy(self.recaser_url)
  	params = {"text":sentence}
	return proxy.translate(params)

    #def translate(self, **kwargs):

    @cherrypy.expose
    @cherrypy.tools.json_out()
    @cherrypy.tools.json_in()
    def translate(self):
        response = cherrypy.response
        response.headers['Content-Type'] = 'application/json'

        body = cherrypy.request.json
        raw_src = body["text"]

        #self.log("The server is working on: %s" %repr(raw_src))
        self.log("The server is working on: %s" % raw_src )
        self.log_info("Request before preprocessing: %s" %repr(raw_src))
        translationDict = {"sourceText":raw_src.strip()}
       
	lower_src = raw_src.lower() 
        tag_src = self.tag(lower_src)
	tokenized_src = self.tokenize(tag_src)

        self.log("Token src is: '%s'" % tokenized_src)
        
	translation = ''

        # query MT engine
	self.log_info("Requesting translation for %s" % repr(tokenized_src))
        result = self._translate(tokenized_src)
        if 'text' in result:
            translation = result['text']
        else:
            return self._timeout_error(tokenized_src, 'translation')
	self.log_info("Received translation: %s" % repr(translation))

	#
	#recased_result = self._recaser(translation)
	#if 'text' in recased_result:
	#	recased_trans=recased_result['text']
	#else:
	#	recased_trans=translation
	rejoinhash_trans = self.rejoinhash(translation)
	detokenized_trans = self.detokenize(rejoinhash_trans)
	#detruecased_trans = self.detruecase(detokenized_trans)
	#translatedText = self.filter.filter(detruecased_trans)
        translatedText = self.filter.filter(detokenized_trans)

	#translationDict = {"translatedText":translatedText}

        data = {"text" : translatedText,
                "version" : "0.1.2pre"}
        #self.log("The server is returning: %s" %self._dump_json(data))
        #return self._dump_json(data)
        return data


    @cherrypy.expose
    def index(self):
        return ""

    def log_info(self, message):
        if self.verbose > 0:
            self.log(message, level=logging.INFO)

    def log(self, message, level=logging.INFO):
        logger = logging.getLogger('translation_log.info')
        logger.info(message)

if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('-ip', help='server ip to bind to, default: localhost', default="127.0.0.1")
    parser.add_argument('-port', action='store', help='server port to bind to, default: 8080', type=int, default=8080)
    parser.add_argument('-nthreads', help='number of server threads, default: 8', type=int, default=8)
    parser.add_argument('-mosesurl', dest="moses_url", action='store', help='url of mosesserver', required=True)
    #parser.add_argument('-recaserurl', dest="recaser_url", action='store', help='url of moses recaser', required=False)
    parser.add_argument('-moseshome', dest="moses_home", action='store', help='path to mosesdecoder installation', required=True)
    parser.add_argument('-timeout', help='timeout for call to translation engine, default: unlimited', type=int)
    parser.add_argument('-pretty', action='store_true', help='pretty print json')
    parser.add_argument('-slang', help='source language code')
    parser.add_argument('-tlang', help='target language code')
    parser.add_argument('-logprefix', help='logfile prefix, default: write to stderr')
    parser.add_argument('-verbose', help='verbosity level, default: 0', type=int, default=0)

    args = parser.parse_args(sys.argv[1:])

    if args.logprefix:
        init_log("%s.trans.log" %args.logprefix)

    cherrypy.config.update({'server.request_queue_size' : 1000,
                            'server.socket_port': args.port,
                            'server.thread_pool': args.nthreads,
                            'server.socket_host': args.ip})
    cherrypy.config.update({'error_page.default': json_error})
    cherrypy.config.update({'log.screen': True})

    if args.logprefix:
        cherrypy.config.update({'log.access_file': "%s.access.log" %args.logprefix,
                                'log.error_file': "%s.error.log" %args.logprefix})

    cherrypy.quickstart(Root(args.moses_home,
			     args.moses_url,
                             slang = args.slang, tlang = args.tlang,
                             pretty = args.pretty,
                             verbose = args.verbose))

