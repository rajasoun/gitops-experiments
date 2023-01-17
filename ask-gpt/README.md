# GitOps Experiments: ask-gpt

This is a Go program that uses the GPT-3 language model to answer questions.

## Prerequisites

- Go 1.15 or later
- An [OpenAI API key][open_api_key]

## Installation

1. Set the `OPENAI_API_KEY` environment variable to your OpenAI API key:

    ```sh
    export OPENAI_API_KEY=<your-api-key>
    ```

2. Build the program:

    ```sh
    make -f .ci/Makefile build ask-gpt
    ```

3. Run the program:

    ```sh
    bin/ask-gpt <question>
    ```

[open_api_key]: https://beta.openai.com/