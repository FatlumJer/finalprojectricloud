using Microsoft.EntityFrameworkCore;
using Serilog;
using StackExchange.Redis;
using System.Text.Json;
using Prometheus; // NEW: Required namespace for metrics

var builder = WebApplication.CreateBuilder(args);

// 1. Setup Redis Connection
var redisConnectionString = builder.Configuration.GetConnectionString("Redis") ?? "redis:6379";
var redis = ConnectionMultiplexer.Connect(redisConnectionString);
builder.Services.AddSingleton<IConnectionMultiplexer>(redis);

// Existing DB Setup
builder.Services.AddDbContext<TodoDb>(opt => opt.UseInMemoryDatabase("TodoList"));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApiDocument(config => {
    config.DocumentName = "TodoAPI";
    config.Title = "TodoAPI v1";
});

// Setup Serilog
builder.Host.UseSerilog((context, config) => {
    config.WriteTo.Console();
    config.ReadFrom.Configuration(context.Configuration);
});

var app = builder.Build();

// ############################################################
// NEW: Metrics Middleware (Must be before Swagger/Routes)
// ############################################################
app.UseHttpMetrics(); // Captures HTTP request counts and durations
app.MapMetrics();     // Exposes the /metrics endpoint for Prometheus scraping

// Enabled Swagger for BOTH Development and Production
app.UseOpenApi();
app.UseSwaggerUi(config =>
{
    config.DocumentTitle = "TodoAPI";
    config.Path = "/swagger";
    config.DocumentPath = "/swagger/{documentName}/swagger.json";
    config.DocExpansion = "list";
});

// Routes
app.MapGet("/todoitems", async (TodoDb db) => await db.Todos.ToListAsync());

app.MapPost("/todoitems", async (Todo todo, TodoDb db, IConnectionMultiplexer redisClient, ILogger<Program> logger) =>
{
    db.Todos.Add(todo);
    await db.SaveChangesAsync();

    // 2. Publish message to Redis channel "todo-updates"
    var sub = redisClient.GetSubscriber();
    var message = JsonSerializer.Serialize(todo);
    await sub.PublishAsync("todo-updates", message);

    logger.LogInformation("Sent message to Redis: {message}", message);

    return Results.Created($"/todoitems/{todo.Id}", todo);
});

app.Run();

// Database models
public class Todo {
    public int Id { get; set; }
    public string? Name { get; set; }
    public bool IsComplete { get; set; }
}

public class TodoDb : DbContext {
    public TodoDb(DbContextOptions<TodoDb> options) : base(options) { }
    public DbSet<Todo> Todos => Set<Todo>();
}