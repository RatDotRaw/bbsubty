using Godot;
using System;
using System.Text;
using System.Threading.Tasks;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

[GlobalClass]
public partial class AMQPTopicListener: AMQPClient
{
	[Export] public AMQPConn AmqpConn;
	[Export] public string ExchangeName = "nixi_topic";
	[Export] public string RoutingKeyPattern = "#"; // e.g. player.login, player.logout

	[Signal] public delegate void MessageReceivedEventHandler(string topic, string message);

	private string _queueName;

	protected override async void StartClientLogic(IChannel channel)
	{
		// if (_queueName != null) 
		// 	return;

		try
		{
			// declare exclusive queue
			var queueDeclareResult = await channel.QueueDeclareAsync(
				queue: "",
				durable: false,
				exclusive: true,
				autoDelete: true
			);
			_queueName = queueDeclareResult.QueueName;
		}
		catch (Exception e)
		{
			GD.PrintErr("TopicConsumer: Failed to create channel/queue: " + e.Message);
			return;
		}
		try {
			// bind to exchange
			await channel.QueueBindAsync(
				queue: _queueName,
				exchange: ExchangeName,
				routingKey: RoutingKeyPattern
			);
			GD.Print($"Bound exclusive queue '{_queueName}' to exchange '{ExchangeName}' with key pattern '{RoutingKeyPattern}'");
		} 
		catch (Exception e)
		{
			GD.PrintErr("TopicConsumer: Failed to bind to queue, does it exist?: " + e.Message);
			return;
		}
		try {

			// start consuming
			var consumer = new AsyncEventingBasicConsumer(channel);
			consumer.ReceivedAsync += OnMessageReceived;

			await channel.BasicConsumeAsync(
				queue: _queueName,
				autoAck: true, // auto ack for simplicity
				consumer: consumer
			);
		}
		catch (Exception e)
		{
			GD.PrintErr("TopicConsumer: Failed to start consuming: " + e.Message);
			return;
		}
	}

	private Task OnMessageReceived(object sender, BasicDeliverEventArgs e)
	{
		var body = e.Body.ToArray();
		var message = Encoding.UTF8.GetString(body);
		var routingKey = e.RoutingKey;

		GD.Print($"message received: [{routingKey}] {message}");

		// marshal to godot's main thread
		CallDeferred(nameof(DispatchMessageToMainThread), routingKey, message);

		return Task.CompletedTask;
	}

	private void DispatchMessageToMainThread(string topic, string message)
	{
		EmitSignal(SignalName.MessageReceived, topic, message);
	}

}
