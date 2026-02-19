using Azure;
using Azure.AI.Inference;
using Azure.Identity;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly ChatCompletionsClient _client;
        private readonly string _modelName;
        private readonly ILogger<ChatService> _logger;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
        {
            _logger = logger;

            var endpoint = configuration["AzureAI:Endpoint"]
                ?? throw new InvalidOperationException("AzureAI:Endpoint is not configured.");
            var apiKey = configuration["AzureAI:ApiKey"] ?? string.Empty;
            _modelName = configuration["AzureAI:ModelName"] ?? "Phi-4";

            if (!string.IsNullOrEmpty(apiKey))
            {
                _client = new ChatCompletionsClient(
                    new Uri(endpoint),
                    new AzureKeyCredential(apiKey));
            }
            else
            {
                _client = new ChatCompletionsClient(
                    new Uri(endpoint),
                    new DefaultAzureCredential());
            }
        }

        public async Task<string> GetChatResponseAsync(List<ChatMessage> conversationHistory)
        {
            try
            {
                var requestOptions = new ChatCompletionsOptions
                {
                    Model = _modelName
                };

                foreach (var msg in conversationHistory)
                {
                    switch (msg.Role.ToLower())
                    {
                        case "system":
                            requestOptions.Messages.Add(new ChatRequestSystemMessage(msg.Content));
                            break;
                        case "user":
                            requestOptions.Messages.Add(new ChatRequestUserMessage(msg.Content));
                            break;
                        case "assistant":
                            requestOptions.Messages.Add(new ChatRequestAssistantMessage(msg.Content));
                            break;
                    }
                }

                var response = await _client.CompleteAsync(requestOptions);
                return response.Value.Content;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting chat response from AI model.");
                return $"Sorry, an error occurred while processing your request: {ex.Message}";
            }
        }
    }
}
