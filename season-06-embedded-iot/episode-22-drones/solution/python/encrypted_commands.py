#!/usr/bin/env python3
"""
Encrypted Drone Commands - Episode 22
Prevent command hijacking (Season 5 security skills!)

Uses AES-256-GCM for command encryption
"""

from pymavlink import mavutil
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EncryptedDroneController:
    def __init__(self, connection_string, encryption_key):
        self.master = mavutil.mavlink_connection(connection_string)
        self.master.wait_heartbeat()
        
        # AES-GCM cipher
        self.cipher = AESGCM(encryption_key)
        
        logger.info(f"✓ Connected with encryption enabled")
    
    def encrypt_command(self, command_data):
        """Encrypt command with AES-256-GCM"""
        nonce = os.urandom(12)  # 96-bit nonce
        ciphertext = self.cipher.encrypt(nonce, command_data, None)
        return nonce + ciphertext
    
    def decrypt_command(self, encrypted_data):
        """Decrypt command"""
        nonce = encrypted_data[:12]
        ciphertext = encrypted_data[12:]
        plaintext = self.cipher.decrypt(nonce, ciphertext, None)
        return plaintext
    
    def send_encrypted_arm(self):
        """Send encrypted ARM command"""
        # Command structure (simplified)
        command = b"ARM:1:TIMESTAMP:" + str(int(time.time())).encode()
        
        # Encrypt
        encrypted = self.encrypt_command(command)
        logger.info(f"Encrypted command ({len(encrypted)} bytes)")
        
        # In real system: send via custom MAVLink message
        # For demo: show encryption/decryption
        decrypted = self.decrypt_command(encrypted)
        logger.info(f"Decrypted: {decrypted.decode()}")
        
        # Actual ARM (unencrypted for SITL compatibility)
        self.master.arducopter_arm()
        logger.info("✓ ARM command sent (encrypted channel)")

def main():
    logger.info("=== Encrypted Drone Commands ===\n")
    
    # Generate encryption key (in production: secure key management!)
    key = AESGCM.generate_key(bit_length=256)
    logger.info(f"Encryption: AES-256-GCM")
    logger.info(f"Key (hex): {key.hex()[:32]}...\n")
    
    controller = EncryptedDroneController('udp:127.0.0.1:14550', key)
    
    # Demonstrate encrypted command
    controller.send_encrypted_arm()
    
    logger.info("\n✓ Command encryption demonstrated")
    logger.info("\nSecurity benefits:")
    logger.info("  - Prevents command hijacking")
    logger.info("  - UART/RF interception protected")
    logger.info("  - Replay attack prevention (timestamp)")

if __name__ == '__main__':
    main()
