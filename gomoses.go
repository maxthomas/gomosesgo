package main

import (
	"flag"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/kolo/xmlrpc"
	"github.com/uber-go/zap"
)

var (
	mosesURI   = flag.String("moses", "", "URI of Moses RPC")
	scriptPath = flag.String("scripts", "", "Path to [pre/post]-processing scripts")
	verbose    = flag.Bool("verbose", false, "Turn on verbose logging")
	debugMode  = flag.Bool("debug", false, "Run in debug mode")
	maxConns   = flag.Int("maxConns", 12, "Maximum number of simultaneous connections to allow")
	port       = flag.Int("port", 8080, "Default port to listen on")

	// logging configuration
	log = zap.New(zap.NewJSONEncoder())
)

func zapLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		t := time.Now()
		c.Next()
		log.Info("Request Handled", zap.Int("status", c.Writer.Status()), zap.Duration("duration", time.Since(t)),
			zap.String("method", c.Request.Method), zap.String("request", c.Request.RequestURI), zap.String("module", "route"), zap.Object("errors", c.Errors.Errors()))
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

func getGinEngine(client *RPCTranslate, tf *TranslationTransformer, maxConns int, debug bool) (r *gin.Engine) {
	if !debug {
		gin.SetMode(gin.ReleaseMode)
	}
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
		zapOptions = append(zapOptions, zap.DebugLevel)
	}
	log = zap.New(zap.NewJSONEncoder(), zapOptions...)
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
	r := getGinEngine(&rpc, &tf, *maxConns, *debugMode)
	portStr := strconv.Itoa(*port)
	mainLog.Info("Backend started on port" + portStr)
	r.Run(":" + portStr) // listen and server on 0.0.0.0:8080
}
