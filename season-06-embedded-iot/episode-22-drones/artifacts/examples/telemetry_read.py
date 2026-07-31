#!/usr/bin/env python3
"""
Telemetry Reader - Episode 22
Read and log drone telemetry
"""

from pymavlink import mavutil
import time
import json

CONNECTION = 'udp:127.0.0.1:14550'

class TelemetryReader:
    def __init__(self, connection_string):
        self.master = mavutil.mavlink_connection(connection_string)
        self.master.wait_heartbeat()
        print(f"Connected to system {self.master.target_system}")
        
        # Request telemetry streams
        self.request_streams()
    
    def request_streams(self):
        self.master.mav.request_data_stream_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_DATA_STREAM_ALL,
            4,  # 4 Hz
            1
        )
    
    def get_gps(self):
        """Get GPS position"""
        msg = self.master.recv_match(type='GLOBAL_POSITION_INT', blocking=True, timeout=1)
        if msg:
            return {
                'lat': msg.lat / 1e7,
                'lon': msg.lon / 1e7,
                'alt': msg.alt / 1000,
                'relative_alt': msg.relative_alt / 1000
            }
        return None
    
    def get_battery(self):
        """Get battery status"""
        msg = self.master.recv_match(type='SYS_STATUS', blocking=True, timeout=1)
        if msg:
            return {
                'voltage': msg.voltage_battery / 1000,
                'current': msg.current_battery / 100,
                'remaining': msg.battery_remaining
            }
        return None
    
    def get_attitude(self):
        """Get attitude (roll, pitch, yaw)"""
        msg = self.master.recv_match(type='ATTITUDE', blocking=True, timeout=1)
        if msg:
            return {
                'roll': msg.roll * 57.3,
                'pitch': msg.pitch * 57.3,
                'yaw': msg.yaw * 57.3
            }
        return None
    
    def get_mode(self):
        """Get flight mode"""
        msg = self.master.recv_match(type='HEARTBEAT', blocking=True, timeout=1)
        if msg:
            mode = mavutil.mode_string_v10(msg)
            return mode
        return None

def main():
    print("=== Telemetry Reader ===\n")
    
    reader = TelemetryReader(CONNECTION)
    
    for i in range(20):
        print(f"\n--- Update {i+1} ---")
        
        gps = reader.get_gps()
        if gps:
            print(f"GPS: {gps['lat']:.6f}, {gps['lon']:.6f}")
            print(f"Alt: {gps['alt']:.1f}m (AGL: {gps['relative_alt']:.1f}m)")
        
        battery = reader.get_battery()
        if battery:
            print(f"Battery: {battery['voltage']:.1f}V, "
                  f"{battery['current']:.1f}A, "
                  f"{battery['remaining']}%")
        
        attitude = reader.get_attitude()
        if attitude:
            print(f"Attitude: R:{attitude['roll']:.1f}° "
                  f"P:{attitude['pitch']:.1f}° "
                  f"Y:{attitude['yaw']:.1f}°")
        
        mode = reader.get_mode()
        if mode:
            print(f"Mode: {mode}")
        
        time.sleep(0.5)
    
    print("\n✓ Telemetry logging complete")

if __name__ == '__main__':
    main()
