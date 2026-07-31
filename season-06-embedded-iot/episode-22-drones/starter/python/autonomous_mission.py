#!/usr/bin/env python3
"""
Autonomous Mission Starter - Episode 22
Upload and execute waypoint mission
"""

from pymavlink import mavutil
import time

CONNECTION = 'udp:127.0.0.1:14550'

class MissionController:
    def __init__(self, connection_string):
        self.master = mavutil.mavlink_connection(connection_string)
        self.master.wait_heartbeat()
        print(f"Connected to system {self.master.target_system}")
    
    def upload_mission(self, waypoints):
        """
        Upload mission waypoints
        waypoints = [(lat, lon, alt), ...]
        """
        print(f"Uploading {len(waypoints)} waypoints...")
        
        # TODO: Implement mission upload
        # 1. Send MISSION_COUNT
        # 2. For each waypoint, send MISSION_ITEM_INT
        # 3. Wait for MISSION_ACK
        
        pass
    
    def start_mission(self):
        """Start AUTO mode mission"""
        # TODO: Set mode to AUTO
        self.master.set_mode('AUTO')
        print("Mission started")
    
    def monitor_mission(self):
        """Monitor mission progress"""
        # TODO: Read MISSION_CURRENT to track progress
        pass

def main():
    controller = MissionController(CONNECTION)
    
    # Simple square mission
    waypoints = [
        (37.7749, -122.4194, 10),  # Point 1
        (37.7750, -122.4194, 10),  # Point 2
        (37.7750, -122.4184, 10),  # Point 3
        (37.7749, -122.4184, 10),  # Point 4
        (37.7749, -122.4194, 10),  # Back to start
    ]
    
    # TODO: Complete autonomous mission
    # controller.upload_mission(waypoints)
    # controller.start_mission()
    # controller.monitor_mission()

if __name__ == '__main__':
    main()
