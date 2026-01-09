using Godot;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System;
using System.Threading.Tasks;

[GlobalClass]
public partial class AMQPConn : Node
{
	public static Node Instance { get; private set; }

	[Export] public string Username = "nixi_project_rabMQ_PM";
	[Export] public string Password = "YoulNeverGuessThisPasswordAndIllChangeItIfYouDo";
	[Export] public string Host = "localhost";
	[Export] public int Port = 36675; // 5672
	[Export] public string VirtualHost = "/"; // RabbitMQ default virtual host

	protected IConnection Connection;

	[Signal]
	public delegate void ConnectionAliveEventHandler(bool connected);
	public bool IsRabbitConnected => Connection?.IsOpen == true;

	private TaskCompletionSource<bool> _connectionTcs = new();
	public Task<bool> ConnectionReady => _connectionTcs.Task;

	public override void _Ready()
	{
		Instance = this;
		GD.Print($"Attempting to Connect to RabbitMQ automatically");
		Connect();
	}

	public async void Connect() 
	{
		// If reconnecting, reset the TCS
		if (_connectionTcs.Task.IsCompleted)
		{
			_connectionTcs = new TaskCompletionSource<bool>();
		}

		bool success = await PerformConnectionLogic();
		_connectionTcs.TrySetResult(success); // resolve task
		EmitSignal(SignalName.ConnectionAlive, success);
	} 

	private async Task<bool> PerformConnectionLogic() {
		try {
			var factory = new ConnectionFactory
			{
				HostName = Host,
				Port = Port,
				UserName = Username,
				Password = Password,
				VirtualHost = VirtualHost
			};
			Connection = await factory.CreateConnectionAsync();
			Connection.ConnectionShutdownAsync += OnConnectionShutdown; // setup disconnect logic
			GD.Print($"Connected to RabbitMQ at [I've hidden this lol]");
			return true;
		}
		catch (Exception e)
		{
			GD.PrintErr($"Failed to connect to RabbitMQ server: {e.Message}");
			GD.PrintErr($"Connection details - Host: {Host}, Port: {Port}, User: {Username}, VHost: {VirtualHost}");
			return false;
		}
	}

	private Task OnConnectionShutdown(object connection, ShutdownEventArgs e)
  	{
		GD.Print($"RabbitMQ connection lost: {e.ReplyText}");
		CallDeferred(nameof(EmitConnectionSignal), false);
		return Task.CompletedTask;
	}
	// helper func to emit a signal for async
	private void EmitConnectionSignal(bool connected) {
		EmitSignal(SignalName.ConnectionAlive, connected);
	}

	public async Task<IChannel> CreateChannel() 
	{
		// wait for the 'gate' to open
		bool isReady = await ConnectionReady;
		if (!isReady || Connection == null || !Connection.IsOpen)
		{
			GD.PrintErr("Channel requested but RabbitMQ connection is not available.");
			return null;
		}
		return await Connection.CreateChannelAsync();
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
