package main

import (
	"flag"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/kolo/xmlrpc"
	"go.uber.org/zap"
)

var (
	mosesURI   = flag.String("moses", os.Getenv("MOSES_RPC_URI"), "URI of Moses RPC")
	scriptPath = flag.String("scripts", "bin/", "Path to [pre/post]-processing scripts")
	verbose    = flag.Bool("verbose", false, "Turn on verbose logging")
	maxConns   = flag.Int("maxConns", 24, "Maximum number of simultaneous connections to allow")
	port       = flag.Int("port", 8080, "Default port to listen on")
	log        *zap.Logger
)

func zapLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		t := time.Now()
		c.Next()
		log.Info("Request Handled",
			zap.Int("status", c.Writer.Status()),
			zap.Duration("duration", time.Since(t)),
			zap.String("method", c.Request.Method),
			zap.String("request", c.Request.RequestURI),
			zap.String("module", "route"),
			zap.Strings("errors", c.Errors.Errors()))
	}
}

// addToGinContext is a middleware which provides the rpc client to handlers
func addToGinContext(client *RPCTranslate, tf *TranslationTransformer) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Set("rpc", client)
		c.Set("tf", tf)
		c.Next()
	}
}

// maxAllowed specifies the maximum number of simultaneous connections
func maxAllowed(n int) gin.HandlerFunc {
	sem := make(chan struct{}, n)
	acquire := func() { sem <- struct{}{} }
	release := func() { <-sem }
	return func(c *gin.Context) {
		acquire() // before request
		c.Next()
		release() // after request
	}
}

func getGinEngine(client *RPCTranslate, tf *TranslationTransformer, maxConns int) (r *gin.Engine) {

	r = gin.New()
	r.Use(gin.Recovery())
	r.Use(zapLogger())
	r.Use(addToGinContext(client, tf))
	r.Use(maxAllowed(maxConns))

	// set up default router
	v1 := r.Group("/v1")
	{
		v1.POST("/translate", routeTranslate)
	}
	r.GET("/health", routeHealth)
	return r
}

func main() {
	flag.Parse()

	// set up logging
	zapOptions := []zap.Option{zap.Fields(zap.String("app", "gomosesgo"))}
	if *verbose {
		log, _ = zap.NewDevelopment(zapOptions...)
	} else {
		log, _ = zap.NewProduction(zapOptions...)
	}

	mainLog := log.With(zap.String("module", "main"))

	if *mosesURI == "" || *scriptPath == "" {
		mainLog.Fatal("Must specify URI of Moses RPC server and path to library scripts")
	}

	client, clientErr := xmlrpc.NewClient(*mosesURI, nil)
	if clientErr != nil {
		mainLog.Fatal("Unable to connect to RPC server", zap.Error(clientErr))
	}
	tf, tfErr := NewTranslationTransformer(*scriptPath)
	if tfErr != nil {
		mainLog.Fatal("Unable to generate transformers", zap.Error(tfErr))
	}

	mainLog.Info("Starting server")
	rpc := RPCTranslate{client}
	r := getGinEngine(&rpc, &tf, *maxConns)
	portStr := strconv.Itoa(*port)
	mainLog.Info("Backend started on port" + portStr)
	r.Run(":" + portStr) // listen and server on 0.0.0.0:8080
}
