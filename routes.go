package main

import (
	"errors"

	"github.com/gin-gonic/gin"
)

// TranslationRequest contains the simple text input
type TranslationRequest struct {
	Text string `form:"text" json:"text" binding:"required"`
}

func routeHealth(c *gin.Context) {
	client := c.MustGet("rpc").(*RPCTranslate)

	ok, err := client.Health()
	if ok {
		c.JSON(200, gin.H{"status": "ok"})
	} else {
		c.JSON(500, gin.H{"status": "down", "error": err.Error()})
	}
}

func routeTranslate(c *gin.Context) {
	// get the rpc client
	client := c.MustGet("rpc").(*RPCTranslate)
	tf := c.MustGet("tf").(*TranslationTransformer)

	// bind the request
	var req TranslationRequest
	c.BindJSON(&req)

	// validate input
	preprocessedSrc, err := tf.Preprocess(req.Text)
	if err != nil {
		c.Error(err)
		c.Error(errors.New("Bad input: " + req.Text))
		c.JSON(500, gin.H{"error": err.Error(), "stage": "pre-process"})
		return
	}

	translatedSrc, err := client.Translate(preprocessedSrc)
	if err != nil {
		c.Error(err)
		c.Error(errors.New("Bad input: " + req.Text))
		c.JSON(500, gin.H{"error": err.Error(), "stage": "translation"})
		return
	}

	finalSrc, err := tf.Postprocess(translatedSrc)
	hashtags := getHashtags(finalSrc)
	if err != nil {
		c.Error(err)
		c.Error(errors.New("Bad input: " + req.Text))
		c.JSON(500, gin.H{"error": err.Error(), "stage": "post-process"})
		return
	}
	c.JSON(200, gin.H{
		"status":   "ok",
		"version":  "1.1.2pre",
		"text":     finalSrc,
		"hashtags": hashtags,
	})
}
