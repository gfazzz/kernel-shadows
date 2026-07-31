#!/usr/bin/env python3
"""
MQTT Publisher Example - Episode 23
KERNEL SHADOWS
"""

import paho.mqtt.client as mqtt
import json
import time

# MQTT Broker settings
BROKER = "localhost"
PORT = 1883
TOPIC = "sensors/temperature/room_01"

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("✓ Connected to MQTT Broker!")
    else:
        print(f"✗ Failed to connect, return code {rc}")

def main():
    print("=== MQTT Publisher Example ===\n")
    
    # Create client
    client = mqtt.Client("temperature_publisher")
    client.on_connect = on_connect
    
    # Connect to broker
    print(f"Connecting to {BROKER}:{PORT}...")
    client.connect(BROKER, PORT)
    client.loop_start()
    
    try:
        # Publish temperature data
        for i in range(10):
            temp = 20 + (i * 0.5)
            data = {
                "sensor_id": "temp_room_01",
                "temperature": temp,
                "humidity": 45 + i,
                "timestamp": int(time.time())
            }
            
            payload = json.dumps(data)
            client.publish(TOPIC, payload)
            print(f"Published: {payload}")
            time.sleep(1)
    
    except KeyboardInterrupt:
        print("\n✓ Stopped")
    
    finally:
        client.loop_stop()
        client.disconnect()

if __name__ == '__main__':
    main()
