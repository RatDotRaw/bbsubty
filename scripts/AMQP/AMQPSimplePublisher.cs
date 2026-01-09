using Godot;
using System;
using System.Text;
using System.Threading.Tasks;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

[GlobalClass]
public partial class AMQPSimplePublisher: AMQPClient
{
	[Export] public AMQPConn AmqpConn;

	public async void PublishMessage(string exchangeName, string routingKeyPattern, string bodyContent) 
	{
		try {
			if (_channel == null || !_channel.IsOpen) {
				_channel = await AmqpConn.CreateChannel();
			}
			if (_channel == null) {
				GD.PrintErr("AMQPSimplePublisher failed to create a channel");
				return;
			}

			await _channel.BasicPublishAsync(
				exchange: exchangeName,
				routingKey: routingKeyPattern,
				body: Encoding.UTF8.GetBytes(bodyContent)
			);
		} catch (Exception e) {
			GD.PrintErr("Error publishing message:", e.Message);
		}
	}


	// needs to be implemented, does nothing, should do nothing
	protected override void StartClientLogic(IChannel channel) {
		return;
	}

}
