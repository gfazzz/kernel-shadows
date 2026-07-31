#!/usr/bin/env python3
"""IoT Sensor (Production) - Episode 23"""
import paho.mqtt.client as mqtt
import json
import time
import random

BROKER = "localhost"
PORT = 1883
TOPIC = "sensors/temperature/room_01"

class IoTSensor:
    def __init__(self, sensor_id, broker, port):
        self.sensor_id = sensor_id
        self.client = mqtt.Client(sensor_id)
        self.client.on_connect = self.on_connect
        self.broker = broker
        self.port = port
    
    def on_connect(self, client, userdata, flags, rc):
        print(f"✓ Connected: {rc}")
    
    def publish_data(self):
        data = {
            "sensor_id": self.sensor_id,
            "temperature": 20 + random.uniform(-2, 2),
            "humidity": 45 + random.uniform(-5, 5),
            "timestamp": int(time.time())
        }
        self.client.publish(TOPIC, json.dumps(data))
        print(f"📤 Published: {data['temperature']:.1f}°C")
    
    def run(self):
        self.client.connect(self.broker, self.port)
        self.client.loop_start()
        try:
            while True:
                self.publish_data()
                time.sleep(5)
        except KeyboardInterrupt:
            self.client.loop_stop()
            self.client.disconnect()

if __name__ == '__main__':
    sensor = IoTSensor("temp_room_01", BROKER, PORT)
    sensor.run()
