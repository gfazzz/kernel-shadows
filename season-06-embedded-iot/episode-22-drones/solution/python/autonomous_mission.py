#!/usr/bin/env python3
"""
Autonomous Mission Controller - Episode 22 SOLUTION
Upload and execute waypoint missions
"""

from pymavlink import mavutil
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

CONNECTION = 'udp:127.0.0.1:14550'

class MissionController:
    def __init__(self, connection_string):
        logger.info("=== Mission Controller ===")
        self.master = mavutil.mavlink_connection(connection_string)
        self.master.wait_heartbeat()
        logger.info(f"Connected to system {self.master.target_system}")
    
    def upload_mission(self, waypoints):
        """
        Upload mission waypoints
        waypoints = [(lat, lon, alt), ...]
        """
        logger.info(f"Uploading mission: {len(waypoints)} waypoints")
        
        # Send mission count
        self.master.mav.mission_count_send(
            self.master.target_system,
            self.master.target_component,
            len(waypoints) + 1,  # +1 for home/takeoff
            0  # Mission type (0=mission)
        )
        
        # Wait for mission_request
        msg = self.master.recv_match(type='MISSION_REQUEST', blocking=True, timeout=5)
        if not msg:
            logger.error("Mission request timeout")
            return False
        
        # Upload home/takeoff waypoint (seq=0)
        self.master.mav.mission_item_int_send(
            self.master.target_system,
            self.master.target_component,
            0,  # seq
            mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT_INT,
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
            1,  # current (1=first waypoint)
            1,  # autocontinue
            0, 0, 0, 0,  # params
            int(waypoints[0][0] * 1e7),  # lat
            int(waypoints[0][1] * 1e7),  # lon
            waypoints[0][2]  # alt
        )
        
        # Upload waypoints
        for i, (lat, lon, alt) in enumerate(waypoints):
            # Wait for request
            msg = self.master.recv_match(type='MISSION_REQUEST', blocking=True, timeout=5)
            if not msg:
                logger.error(f"Timeout at waypoint {i}")
                return False
            
            # Send waypoint
            self.master.mav.mission_item_int_send(
                self.master.target_system,
                self.master.target_component,
                i + 1,  # seq (0 is home)
                mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT_INT,
                mavutil.mavlink.MAV_CMD_NAV_WAYPOINT,
                0,  # current
                1,  # autocontinue
                0, 0, 0, 0,
                int(lat * 1e7),
                int(lon * 1e7),
                alt
            )
            logger.info(f"  Waypoint {i+1}: {lat}, {lon}, {alt}m")
        
        # Wait for ACK
        ack = self.master.recv_match(type='MISSION_ACK', blocking=True, timeout=5)
        if ack and ack.type == 0:
            logger.info("✓ Mission uploaded successfully")
            return True
        else:
            logger.error("Mission upload failed")
            return False
    
    def start_mission(self):
        """Start AUTO mode mission"""
        logger.info("Starting mission (AUTO mode)...")
        
        # Set AUTO mode
        self.master.set_mode('AUTO')
        
        # Wait for mode change
        start = time.time()
        while time.time() - start < 5:
            msg = self.master.recv_match(type='HEARTBEAT', blocking=True, timeout=1)
            if msg:
                mode = mavutil.mode_string_v10(msg)
                if mode == 'AUTO':
                    logger.info("✓ Mission started")
                    return True
        
        logger.error("Failed to enter AUTO mode")
        return False
    
    def monitor_mission(self):
        """Monitor mission progress"""
        logger.info("\n=== Mission Monitoring ===")
        
        last_seq = -1
        while True:
            msg = self.master.recv_match(type='MISSION_CURRENT', blocking=True, timeout=1)
            if msg:
                if msg.seq != last_seq:
                    logger.info(f"Waypoint {msg.seq}")
                    last_seq = msg.seq
                
                # Check if mission complete (back at seq 0)
                if msg.seq == 0 and last_seq > 0:
                    logger.info("✓ Mission complete!")
                    break
            
            # Also check altitude
            pos = self.master.recv_match(type='GLOBAL_POSITION_INT', blocking=True, timeout=1)
            if pos:
                alt = pos.relative_alt / 1000
                logger.info(f"  Altitude: {alt:.1f}m")
            
            time.sleep(1)

def main():
    logger.info("=== Autonomous Surveillance Mission ===\n")
    
    controller = MissionController(CONNECTION)
    
    # Square surveillance pattern
    # (San Francisco coordinates for example)
    waypoints = [
        (37.7749, -122.4194, 15),  # Start
        (37.7750, -122.4194, 15),  # North
        (37.7750, -122.4184, 15),  # East
        (37.7749, -122.4184, 15),  # South
        (37.7749, -122.4194, 15),  # Back to start
    ]
    
    logger.info("Mission: Square surveillance pattern")
    logger.info(f"Waypoints: {len(waypoints)}")
    logger.info(f"Altitude: 15m AGL\n")
    
    # Upload mission
    if not controller.upload_mission(waypoints):
        logger.error("Mission upload failed, aborting")
        return
    
    # Start mission
    input("\nPress ENTER to start mission (make sure ARMED!)...")
    
    if not controller.start_mission():
        logger.error("Failed to start mission")
        return
    
    # Monitor
    try:
        controller.monitor_mission()
        logger.info("\n✓ Autonomous mission complete!")
    except KeyboardInterrupt:
        logger.warning("\n! Mission interrupted")
        # Emergency RTL
        controller.master.set_mode('RTL')

if __name__ == '__main__':
    main()
