using Godot;
using RabbitMQ.Client;
using System;
using System.Threading.Tasks;

[GlobalClass]
public partial class AMQPConn : Node
{
	public static AMQPConn Instance { get; private set; }

	[Export] public string Username = "user";
	[Export] public string Password = "changeme";
	[Export] public string HostOrUrl = "localhost"; // Can be "localhost" or "amqp://server"

	protected IConnection Connection;
	protected IChannel Channel;

	public bool IsConnected => Connection?.IsOpen == true && Channel != null;

	public override void _Ready()
	{
		Instance = this;
		GD.Print($"AMQPConn created for user: {Username}");
		_ = Connect(); // Fire and forget async
	}

	protected virtual async Task Connect()
	{
		var factory = new ConnectionFactory();
		
		// Handle both hostnames and full AMQP URLs
		if (HostOrUrl.StartsWith("amqp://", StringComparison.OrdinalIgnoreCase))
			factory.Uri = new Uri(HostOrUrl);
		else
			factory.HostName = HostOrUrl;
		
		factory.UserName = Username;
		factory.Password = Password;
		
		try
		{
			Connection = await factory.CreateConnectionAsync();
			Channel = await Connection.CreateChannelAsync();
			Console.WriteLine("Connected to RabbitMQ");
		}
		catch (Exception e)
		{
			GD.PrintErr("Failed to connect to RabbitMQ server: " + e.Message);
			return;
		}
	}
	
	public override void _ExitTree()
	{
		if (Connection != null)
		{
			Connection.CloseAsync(); // Non-blocking close
			GD.Print("Disconnected from RabbitMQ");
		}
		base._ExitTree();
	}
}
