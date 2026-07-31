#!/usr/bin/env python3
"""
MQTT Subscriber Example - Episode 23
KERNEL SHADOWS
"""

import paho.mqtt.client as mqtt
import json

# MQTT Broker settings
BROKER = "localhost"
PORT = 1883
TOPIC = "sensors/#"  # Wildcard: все sensors

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("✓ Connected to MQTT Broker!")
        client.subscribe(TOPIC)
        print(f"✓ Subscribed to: {TOPIC}\n")
    else:
        print(f"✗ Failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        print(f"📨 Topic: {msg.topic}")
        print(f"   Data: {payload}\n")
    except json.JSONDecodeError:
        print(f"📨 Topic: {msg.topic}")
        print(f"   Data: {msg.payload.decode()}\n")

def main():
    print("=== MQTT Subscriber Example ===\n")
    
    # Create client
    client = mqtt.Client("sensor_monitor")
    client.on_connect = on_connect
    client.on_message = on_message
    
    # Connect to broker
    print(f"Connecting to {BROKER}:{PORT}...")
    client.connect(BROKER, PORT)
    
    # Start listening
    try:
        client.loop_forever()
    except KeyboardInterrupt:
        print("\n✓ Stopped")
        client.disconnect()

if __name__ == '__main__':
    main()
