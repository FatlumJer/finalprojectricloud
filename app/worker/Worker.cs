using StackExchange.Redis;
using System.Text.Json;

namespace worker;

public class Worker : BackgroundService
{
    private readonly ILogger<Worker> _logger;
    private readonly IConnectionMultiplexer _redis;

    public Worker(ILogger<Worker> logger, IConfiguration configuration)
    {
        _logger = logger;
        // Connect using the same K8s environment variable
        var connectionString = configuration.GetConnectionString("Redis") ?? "redis:6379";
        _logger.LogInformation("Connecting to Redis at: {conn}", connectionString);
        _redis = ConnectionMultiplexer.Connect(connectionString);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var sub = _redis.GetSubscriber();

        // Subscribe to the channel the API is publishing to
        await sub.SubscribeAsync("todo-updates", (channel, message) => 
        {
            _logger.LogInformation("🚀 [WORKER] Received new task from Redis: {task}", message);
            
            // Logic for processing goes here (e.g., sending notification)
        });

        _logger.LogInformation("Worker subscribed to 'todo-updates' channel. Waiting for messages...");

        // Keep the background process alive
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(10000, stoppingToken);
        }
    }
}