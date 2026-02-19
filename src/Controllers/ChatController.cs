using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;
using System.Text.Json;

namespace ZavaStorefront.Controllers;

public class ChatController : Controller
{
    private readonly ChatService _chatService;
    private readonly ILogger<ChatController> _logger;
    private const string SessionKey = "ChatHistory";

    public ChatController(ChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    public IActionResult Index()
    {
        var messages = GetChatHistory();
        var viewModel = new ChatViewModel
        {
            Messages = messages
        };
        return View(viewModel);
    }

    [HttpPost]
    public async Task<IActionResult> SendMessage(ChatViewModel model)
    {
        if (string.IsNullOrWhiteSpace(model.UserMessage))
        {
            return RedirectToAction("Index");
        }

        _logger.LogInformation("User sent chat message: {Message}", model.UserMessage);

        var messages = GetChatHistory();

        // Add system message if this is the start of the conversation
        if (messages.Count == 0)
        {
            messages.Add(new ChatMessage
            {
                Role = "system",
                Content = "You are a helpful assistant for the Zava Storefront. Help customers with questions about products, pricing, and general inquiries."
            });
        }

        // Add user message
        messages.Add(new ChatMessage
        {
            Role = "user",
            Content = model.UserMessage
        });

        // Get AI response
        var response = await _chatService.GetChatResponseAsync(messages);

        // Add assistant response
        messages.Add(new ChatMessage
        {
            Role = "assistant",
            Content = response
        });

        SaveChatHistory(messages);

        var viewModel = new ChatViewModel
        {
            Messages = messages
        };

        return View("Index", viewModel);
    }

    [HttpPost]
    public IActionResult ClearChat()
    {
        HttpContext.Session.Remove(SessionKey);
        return RedirectToAction("Index");
    }

    private List<ChatMessage> GetChatHistory()
    {
        var json = HttpContext.Session.GetString(SessionKey);
        if (string.IsNullOrEmpty(json))
        {
            return new List<ChatMessage>();
        }
        return JsonSerializer.Deserialize<List<ChatMessage>>(json) ?? new List<ChatMessage>();
    }

    private void SaveChatHistory(List<ChatMessage> messages)
    {
        var json = JsonSerializer.Serialize(messages);
        HttpContext.Session.SetString(SessionKey, json);
    }
}
