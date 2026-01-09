using Godot;
using System;
using RabbitMQ.Client;
using System.Threading.Tasks;

public abstract partial class AMQPClient : Node
{
	[Export] public AMQPConn AmqpConn;

	protected IChannel _channel;

	public override void _Ready()
	{
		if (AmqpConn == null)
		{
			AmqpConn = GetNodeOrNull<AMQPConn>("/root/AmqpConn");
			if (AmqpConn == null)
				throw new Exception("AMQPConn is not assigned in editor or found as root note.");
		}
		
		AmqpConn.ConnectionAlive += Initialize;
	}

	public virtual async void Initialize(bool IsConnected)
	{
		if (IsConnected) {
			await AmqpConn.ConnectionReady;
			_channel = await AmqpConn.CreateChannel();
			GD.Print("AMQPClient created a channel");
			StartClientLogic(_channel);
		}
	}

	protected abstract void StartClientLogic(IChannel channel);
}
