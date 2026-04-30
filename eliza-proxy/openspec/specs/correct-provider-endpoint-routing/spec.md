# correct-provider-endpoint-routing Specification

## Purpose
TBD - created by archiving change fix-model-endpoint-routing. Update Purpose after archive.
## Requirements
### Requirement: Router correctly maps model IDs to provider-specific endpoints per Eliza API documentation
The system SHALL route model requests to provider-specific endpoints as defined in the Eliza API documentation.
Router SHALL prioritize specific provider routes over general provider catch-alls.

#### Scenario: Google models route to /google/v1 endpoint
- **WHEN** model ID is `gemini-2.0-flash`, `gemini-2.5-flash`, or `gemini-2.5-pro`
- **THEN** router configures URL as `${baseUrl}/google/v1/chat/completions`
- **THEN** format is set to `openai`
- **THEN** model ID is passed through unchanged

#### Scenario: DeepSeek models route to /raw/internal/deepseek/v1 endpoint
- **WHEN** model ID is `deepseek-chat`, `deepseek-reasoner`, or `deepseek-ai/deepseek-r1`
- **THEN** router configures URL as `${baseUrl}/raw/internal/deepseek/v1/chat/completions`
- **THEN** format is set to `openai`
- **THEN** model ID is passed through unchanged

#### Scenario: DeepSeek Terminus models preserve existing endpoint
- **WHEN** model ID is `deepseek-v3-1-terminus` or `deepseek-v3.1-terminus`
- **THEN** router configures URL as `${baseUrl}/raw/internal/deepseek-v3-1-terminus/v1/chat/completions`
- **THEN** model parameter is set to `default`

#### Scenario: DeepSeek V3.2 models preserve existing endpoint
- **WHEN** model ID is `deepseek-v3-2` or `deepseek-v3.2`
- **THEN** router configures URL as `${baseUrl}/raw/internal/deepseek-v3-2/v1/chat/completions`
- **THEN** model parameter is set to `default`

#### Scenario: Claude models preserve existing endpoint
- **WHEN** model ID is `claude-haiku-4-5`, `claude-opus-4-6`, or `claude-sonnet-4-5`
- **THEN** router configures URL as `${baseUrl}/raw/anthropic/v1/messages`
- **THEN** format is set to `anthropic`
- **THEN** thinking support is detected for Claude 3.7 models

#### Scenario: General provider models not in specific lists route to OpenRouter
- **WHEN** model ID contains provider prefix (mistral, xai, alibaba, moonshotai, zhipu, meta, sber) but not google/deepseek
- **THEN** router configures URL as `${baseUrl}/raw/openrouter/v1/chat/completions`
- **THEN** format is set to `openai`
- **THEN** model ID is passed through unchanged

#### Scenario: Provider-specific routes take precedence over OpenRouter catch-all
- **WHEN** model ID is `gemini-2.5-pro` (Google provider)
- **THEN** router matches the specific Google route before checking the OpenRouter catch-all
- **THEN** final URL is `/google/v1/chat/completions` (NOT `/raw/openrouter/v1/chat/completions`)

#### Scenario: DeepSeek routing excludes Terminus and V3.2 variants
- **WHEN** model ID is `deepseek-v3-1-terminus`
- **THEN** router matches the specific Terminus route (line 97-99 in routing.js)
- **THEN** router does NOT match the general DeepSeek route
- **THEN** final URL is `/raw/internal/deepseek-v3-1-terminus/v1/chat/completions`

