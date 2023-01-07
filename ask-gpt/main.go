package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/rajasoun/ask-gpt/cli"
)

type Data struct {
	ID      string                 `json:"id"`
	Object  string                 `json:"object"`
	Created int                    `json:"created"`
	Model   string                 `json:"model"`
	Choices []TextCompletionChoice `json:"choices"`
	Usage   TextCompletionUsage    `json:"usage"`
}

type TextCompletionChoice struct {
	Text         string  `json:"text"`
	Index        int     `json:"index"`
	LogProbs     *string `json:"logprobs"`
	FinishReason string  `json:"finish_reason"`
}

type TextCompletionUsage struct {
	PromptTokens     int `json:"prompt_tokens"`
	CompletionTokens int `json:"completion_tokens"`
	TotalTokens      int `json:"total_tokens"`
}

func main() {
	var err error
	var config map[string]string
	if err = cli.CreateConfigDirectory(); err != nil {
		log.Fatal(err)
	}

	if config, err = cli.ReadYml(); err != nil {
		log.Fatal(err)
	}

	if len(config["auth"]) < 51 {
		log.Fatal("Ensure to insert a valid token in cligpt.yml file.")
	}
	if len(os.Args) != 2 {
		fmt.Println(`No arguments!
		$ gpt-helper 'How does ChatGPT API work?'`)
		os.Exit(0)
	} else {

		client := &http.Client{}
		var data = strings.NewReader(`{
		  "model": "` + config["model"] + `",
		  "prompt": "` + os.Args[1] + `",
		  "temperature": 0.7,
		  "max_tokens": ` + config["max_tokens"] + `,
		  "top_p": 1,
		  "frequency_penalty": 0,
		  "presence_penalty": 0
		}`)
		req, err := http.NewRequest("POST", "https://api.openai.com/v1/completions", data)
		if err != nil {
			fmt.Println(err, req)
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", `Bearer `+config["auth"]+``)
		resp, err := client.Do(req)
		if err != nil {
			log.Fatal("The token is valid?", err)
		}
		// check if the token is valid.
		if resp.StatusCode == 401 {
			fmt.Println("The token is invalid")
			os.Exit(0)
		}
		defer resp.Body.Close()
		bodyText, err := ioutil.ReadAll(resp.Body)

		if err != nil {
			log.Println(err)
		}
		var response Data
		json.Unmarshal(bodyText, &response)
		if err != nil {
			log.Println(err)
		}
		choice := response.Choices[0]
		text := choice.Text
		fmt.Println(text)
	}
}
