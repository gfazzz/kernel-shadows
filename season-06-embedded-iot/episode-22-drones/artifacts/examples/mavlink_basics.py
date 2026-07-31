#!/usr/bin/env python3
"""
Basic MAVLink Connection - Episode 22
KERNEL SHADOWS

Simple example: Connect to drone and read telemetry
"""

from pymavlink import mavutil
import time

# Connection string
# Options:
# - Serial: '/dev/ttyUSB0' (baudrate 57600)
# - UDP: 'udp:127.0.0.1:14550'
# - TCP: 'tcp:127.0.0.1:5760'
CONNECTION = 'udp:127.0.0.1:14550'  # SITL simulator

def main():
    print("=== MAVLink Basic Connection ===")
    print(f"Connecting to: {CONNECTION}")
    
    # Create connection
    master = mavutil.mavlink_connection(CONNECTION)
    
    # Wait for heartbeat
    print("Waiting for heartbeat...")
    master.wait_heartbeat()
    print(f"✓ Heartbeat from system {master.target_system}")
    
    # Request data streams
    master.mav.request_data_stream_send(
        master.target_system,
        master.target_component,
        mavutil.mavlink.MAV_DATA_STREAM_ALL,
        4,  # Hz
        1   # Start
    )
    
    print("\nReceiving telemetry (10 seconds)...")
    start = time.time()
    
    while time.time() - start < 10:
        msg = master.recv_match(blocking=True, timeout=1)
        if msg:
            msg_type = msg.get_type()
            
            # GPS position
            if msg_type == 'GLOBAL_POSITION_INT':
                lat = msg.lat / 1e7
                lon = msg.lon / 1e7
                alt = msg.alt / 1000
                print(f"GPS: {lat:.6f}, {lon:.6f}, Alt: {alt:.1f}m")
            
            # Attitude
            elif msg_type == 'ATTITUDE':
                roll = msg.roll * 57.3  # rad to deg
                pitch = msg.pitch * 57.3
                yaw = msg.yaw * 57.3
                print(f"Attitude: R:{roll:.1f}° P:{pitch:.1f}° Y:{yaw:.1f}°")
            
            # Battery
            elif msg_type == 'SYS_STATUS':
                voltage = msg.voltage_battery / 1000
                current = msg.current_battery / 100
                remaining = msg.battery_remaining
                print(f"Battery: {voltage:.1f}V, {current:.1f}A, {remaining}%")
    
    print("\n✓ Connection test complete")

if __name__ == '__main__':
    main()
