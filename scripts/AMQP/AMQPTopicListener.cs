using Godot;
using System;
using System.Text;
using System.Threading.Tasks;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

[GlobalClass]
public partial class AMQPTopicListener : AMQPConn
{
	[Export] public string ExchangeName = "nixi_topic";
	[Export] public string RoutingKeyPattern = "#"; // e.g. player.login, player.logout

	[Signal] public delegate void MessageReceivedEventHandler(string topic, string message);

	private string _queueName;

	protected override async Task Connect()
	{
		await base.Connect();
		if (!IsConnected) return;

		try
		{
			// declare topic exchange
			await Channel.ExchangeDeclareAsync(
				exchange: ExchangeName,
				type: ExchangeType.Topic
				// durable: true
			);

			// declare exclusive queue
			var queueDeclareResult = await Channel.QueueDeclareAsync(
				queue: "",
				durable: false,
				exclusive: true,
				autoDelete: true
			);

			_queueName = queueDeclareResult.QueueName;

			// bind to exchange
			await Channel.QueueBindAsync(
				queue: _queueName,
				exchange: ExchangeName,
				routingKey: RoutingKeyPattern
			);

			GD.Print($"Bound exclusive queue '{_queueName}' to exchange '{ExchangeName}' with key pattern '{RoutingKeyPattern}'");

			// start consuming
			var consumer = new AsyncEventingBasicConsumer(Channel);
			consumer.ReceivedAsync += OnMessageReceived;

			await Channel.BasicConsumeAsync(
				queue: _queueName,
				autoAck: true, // auto ack for simplicity
				consumer: consumer
			);
		}
		catch (Exception e)
		{
			GD.PrintErr("Failed to initialize topic consumer: " + e.Message);
		}
	}

	private Task OnMessageReceived(object sender, BasicDeliverEventArgs e)
	{
		var body = e.Body.ToArray();
		var message = Encoding.UTF8.GetString(body);
		var routingKey = e.RoutingKey;

		GD.Print($"[{routingKey}] {message}");

		// marshal to godot's main thread
		CallDeferred(nameof(DispatchMessageToMainThread), routingKey, message);

		return Task.CompletedTask;
	}

	private void DispatchMessageToMainThread(string topic, string message)
	{
		EmitSignal(SignalName.MessageReceived, topic, message);
	}

}
