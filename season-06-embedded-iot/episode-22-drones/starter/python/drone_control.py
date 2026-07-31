#!/usr/bin/env python3
"""
Drone Control Starter - Episode 22
KERNEL SHADOWS

Mission: Control surveillance drone
TODO: Complete the TODOs below
"""

from pymavlink import mavutil
import time

# Connection (use simulator first!)
CONNECTION = 'udp:127.0.0.1:14550'  # SITL simulator

class DroneController:
    def __init__(self, connection_string):
        print("=== Drone Controller - Episode 22 ===")
        print(f"Connecting to: {connection_string}\n")
        
        # TODO 1: Create MAVLink connection
        # Hint: mavutil.mavlink_connection()
        self.master = None  # <-- Replace
        
        if self.master:
            # Wait for heartbeat
            print("Waiting for heartbeat...")
            # TODO 2: Wait for heartbeat
            # Hint: self.master.wait_heartbeat()
            
            print(f"✓ Connected to system {self.master.target_system}\n")
    
    def arm(self):
        """ARM the drone"""
        print("Arming drone...")
        
        # TODO 3: Send ARM command
        # Hint: MAV_CMD_COMPONENT_ARM_DISARM with param1=1
        # self.master.mav.command_long_send(...)
        
        # Wait for ACK
        ack = self.master.recv_match(type='COMMAND_ACK', blocking=True, timeout=3)
        if ack and ack.result == 0:
            print("✓ Armed\n")
            return True
        else:
            print("✗ Arm failed\n")
            return False
    
    def disarm(self):
        """DISARM the drone"""
        print("Disarming...")
        
        # TODO 4: Send DISARM command (param1=0)
        
        time.sleep(1)
        print("✓ Disarmed\n")
    
    def takeoff(self, altitude):
        """Takeoff to specified altitude"""
        print(f"Taking off to {altitude}m...")
        
        # TODO 5: Send TAKEOFF command
        # Hint: MAV_CMD_NAV_TAKEOFF, param7=altitude
        # self.master.mav.command_long_send(
        #     self.master.target_system,
        #     self.master.target_component,
        #     mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
        #     0, 0, 0, 0, 0, 0, 0, altitude
        # )
        
        print(f"✓ Takeoff command sent\n")
    
    def land(self):
        """Land the drone"""
        print("Landing...")
        
        # TODO 6: Set mode to LAND
        # Hint: self.master.set_mode('LAND')
        
        print("✓ Land mode set\n")
    
    def get_telemetry(self):
        """Read basic telemetry"""
        # TODO 7: Get GPS position
        # msg = self.master.recv_match(type='GLOBAL_POSITION_INT', ...)
        
        # TODO 8: Get battery
        # msg = self.master.recv_match(type='SYS_STATUS', ...)
        
        # TODO 9: Get altitude
        
        return {
            'lat': 0,
            'lon': 0,
            'alt': 0,
            'battery': 0
        }

def main():
    # Initialize controller
    controller = DroneController(CONNECTION)
    
    if not controller.master:
        print("✗ Connection failed")
        return
    
    # TODO 10: Implement flight sequence
    # 1. ARM
    # 2. TAKEOFF to 10m
    # 3. Wait 5 seconds
    # 4. Read telemetry
    # 5. LAND
    # 6. DISARM
    
    print("=== Flight Sequence ===")
    
    # Your code here:
    # if controller.arm():
    #     controller.takeoff(10)
    #     ...
    
    print("\n✓ Mission complete!")

if __name__ == '__main__':
    main()
