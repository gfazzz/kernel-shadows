#!/usr/bin/env python3
"""
Drone Controller - Episode 22 SOLUTION
KERNEL SHADOWS Surveillance Drone

Production-ready drone control system
"""

from pymavlink import mavutil
import time
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

CONNECTION = 'udp:127.0.0.1:14550'  # Change for real drone

class DroneController:
    def __init__(self, connection_string):
        logger.info("=== Drone Controller Initializing ===")
        logger.info(f"Connection: {connection_string}")
        
        self.master = mavutil.mavlink_connection(connection_string)
        
        logger.info("Waiting for heartbeat...")
        self.master.wait_heartbeat()
        logger.info(f"✓ Heartbeat from system {self.master.target_system}")
        
        # Request telemetry streams
        self.request_data_streams()
        
        # Flight state
        self.armed = False
        self.flying = False
    
    def request_data_streams(self):
        """Request telemetry streams"""
        self.master.mav.request_data_stream_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_DATA_STREAM_ALL,
            4,  # 4 Hz
            1   # Start
        )
        logger.info("Telemetry streams requested")
    
    def wait_for_mode(self, target_mode, timeout=10):
        """Wait for mode change"""
        start = time.time()
        while time.time() - start < timeout:
            msg = self.master.recv_match(type='HEARTBEAT', blocking=True, timeout=1)
            if msg:
                current_mode = mavutil.mode_string_v10(msg)
                if current_mode == target_mode:
                    return True
        return False
    
    def arm(self):
        """ARM the drone"""
        logger.info("Arming drone...")
        
        # Pre-arm checks
        if not self.check_pre_arm():
            logger.error("Pre-arm checks failed!")
            return False
        
        # Send ARM command
        self.master.mav.command_long_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
            0,  # confirmation
            1,  # 1=arm, 0=disarm
            0, 0, 0, 0, 0, 0
        )
        
        # Wait for ACK
        ack = self.master.recv_match(type='COMMAND_ACK', blocking=True, timeout=3)
        if ack and ack.result == 0:
            self.armed = True
            logger.info("✓ Armed successfully")
            return True
        else:
            logger.error(f"✗ Arm failed (result: {ack.result if ack else 'timeout'})")
            return False
    
    def disarm(self):
        """DISARM the drone"""
        logger.info("Disarming...")
        
        self.master.mav.command_long_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
            0,
            0,  # 0 = disarm
            0, 0, 0, 0, 0, 0
        )
        
        time.sleep(1)
        self.armed = False
        self.flying = False
        logger.info("✓ Disarmed")
    
    def takeoff(self, altitude):
        """Takeoff to specified altitude"""
        logger.info(f"Takeoff to {altitude}m...")
        
        # Set GUIDED mode first
        self.master.set_mode('GUIDED')
        if not self.wait_for_mode('GUIDED', timeout=5):
            logger.error("Failed to enter GUIDED mode")
            return False
        
        # Send takeoff command
        self.master.mav.command_long_send(
            self.master.target_system,
            self.master.target_component,
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
            0,
            0, 0, 0, 0, 0, 0,
            altitude
        )
        
        # Wait for altitude
        logger.info("Climbing...")
        start_alt = self.get_altitude()
        while True:
            current_alt = self.get_altitude()
            if current_alt >= altitude * 0.95:  # 95% of target
                break
            logger.info(f"Altitude: {current_alt:.1f}m")
            time.sleep(1)
        
        self.flying = True
        logger.info(f"✓ Reached {altitude}m")
        return True
    
    def land(self):
        """Land the drone"""
        logger.info("Landing...")
        
        self.master.set_mode('LAND')
        if self.wait_for_mode('LAND', timeout=5):
            logger.info("✓ Land mode set")
            
            # Wait for touchdown
            while True:
                alt = self.get_altitude()
                if alt < 0.5:  # 50cm from ground
                    break
                logger.info(f"Descending: {alt:.1f}m")
                time.sleep(1)
            
            self.flying = False
            logger.info("✓ Landed")
            return True
        else:
            logger.error("Failed to enter LAND mode")
            return False
    
    def rtl(self):
        """Return to launch"""
        logger.info("RTL (Return to Launch)...")
        self.master.set_mode('RTL')
        logger.info("✓ RTL mode set")
    
    def check_pre_arm(self):
        """Pre-arm safety checks"""
        logger.info("Running pre-arm checks...")
        
        # Check GPS
        gps = self.get_gps()
        if gps and gps['sats'] < 8:
            logger.error(f"GPS insufficient: {gps['sats']} sats (need 8+)")
            return False
        
        # Check battery
        battery = self.get_battery()
        if battery and battery['remaining'] < 80:
            logger.warning(f"Battery low: {battery['remaining']}% (recommend 80%+)")
        
        logger.info("✓ Pre-arm checks passed")
        return True
    
    def get_gps(self):
        """Get GPS status"""
        msg = self.master.recv_match(type='GPS_RAW_INT', blocking=True, timeout=1)
        if msg:
            return {
                'sats': msg.satellites_visible,
                'fix': msg.fix_type,
                'lat': msg.lat / 1e7,
                'lon': msg.lon / 1e7
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
    
    def get_altitude(self):
        """Get current altitude (AGL)"""
        msg = self.master.recv_match(type='GLOBAL_POSITION_INT', blocking=True, timeout=1)
        if msg:
            return msg.relative_alt / 1000  # mm to m
        return 0
    
    def get_telemetry(self):
        """Get comprehensive telemetry"""
        telemetry = {}
        
        gps = self.get_gps()
        if gps:
            telemetry['gps'] = gps
        
        battery = self.get_battery()
        if battery:
            telemetry['battery'] = battery
        
        telemetry['altitude'] = self.get_altitude()
        telemetry['armed'] = self.armed
        telemetry['flying'] = self.flying
        
        return telemetry

def main():
    logger.info("=== Surveillance Drone - Episode 22 ===\n")
    
    # Initialize
    controller = DroneController(CONNECTION)
    
    try:
        # Flight sequence
        logger.info("=== Flight Sequence Start ===\n")
        
        # 1. ARM
        if not controller.arm():
            logger.error("Failed to arm, aborting")
            return
        
        time.sleep(2)
        
        # 2. TAKEOFF
        if not controller.takeoff(10):
            logger.error("Takeoff failed")
            controller.disarm()
            return
        
        # 3. Hold position
        logger.info("\n=== Surveillance Mode (10 seconds) ===")
        for i in range(10):
            telemetry = controller.get_telemetry()
            logger.info(f"Alt: {telemetry['altitude']:.1f}m, "
                       f"Battery: {telemetry.get('battery', {}).get('remaining', 0)}%")
            time.sleep(1)
        
        # 4. LAND
        logger.info("\n=== Landing Sequence ===")
        controller.land()
        
        time.sleep(2)
        
        # 5. DISARM
        controller.disarm()
        
        logger.info("\n✓ Mission Complete!")
        
    except KeyboardInterrupt:
        logger.warning("\n! Emergency stop!")
        controller.land()
        time.sleep(2)
        controller.disarm()
    
    except Exception as e:
        logger.error(f"Error: {e}")
        controller.rtl()  # Safety: Return to launch

if __name__ == '__main__':
    main()
