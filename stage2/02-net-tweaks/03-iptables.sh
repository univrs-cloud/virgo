#!/bin/bash -e

# Create rules directory
mkdir -p "${ROOTFS_DIR}/etc/iptables"

# Create IPv4 rules file
cat > "${ROOTFS_DIR}/etc/iptables/rules.v4" << 'EOF'
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow loopback (localhost) - this allows PCP ports on 127.0.0.1
-A INPUT -i lo -j ACCEPT

# Allow established and related connections
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow ICMP (ping)
-A INPUT -p icmp -j ACCEPT

# Allow specific services from ANY IPv4 address
-A INPUT -p tcp --dport 22 -j ACCEPT     # SSH
-A INPUT -p tcp --dport 25 -j ACCEPT     # SMTP
-A INPUT -p tcp --dport 53 -j ACCEPT     # DNS
-A INPUT -p udp --dport 53 -j ACCEPT     # DNS
-A INPUT -p tcp --dport 80 -j ACCEPT     # HTTP
-A INPUT -p udp --dport 137 -j ACCEPT    # NetBIOS Name Service
-A INPUT -p udp --dport 138 -j ACCEPT    # NetBIOS Datagram Service
-A INPUT -p tcp --dport 139 -j ACCEPT    # NetBIOS Session Service
-A INPUT -p tcp --dport 443 -j ACCEPT    # HTTPS
-A INPUT -p udp --dport 443 -j ACCEPT    # HTTPS (QUIC/HTTP3)
-A INPUT -p tcp --dport 445 -j ACCEPT    # SMB/CIFS
-A INPUT -p tcp --dport 465 -j ACCEPT    # SMTPS
-A INPUT -p tcp --dport 587 -j ACCEPT    # SMTP Submission
-A INPUT -p tcp --dport 993 -j ACCEPT    # IMAPS
-A INPUT -p tcp --dport 3000 -j ACCEPT   # Custom service
-A INPUT -p tcp --dport 3478 -j ACCEPT   # STUN
-A INPUT -p udp --dport 3478 -j ACCEPT   # STUN (UDP)
-A INPUT -p tcp --dport 4190 -j ACCEPT   # Sieve
-A INPUT -p udp --dport 5353 -j ACCEPT   # mDNS/Bonjour (macOS discovery)
-A INPUT -p udp --dport 5355 -j ACCEPT   # LLMNR (Windows discovery)
-A INPUT -p tcp --dport 6881 -j ACCEPT   # qBittorrent
-A INPUT -p udp --dport 6881 -j ACCEPT   # qBittorrent
-A INPUT -p udp --dport 51820 -j ACCEPT  # WireGuard VPN

# PCP ports (4330, 44321, 44322, 44323) are NOT listed here
# They're only accessible via localhost (covered by -i lo rule above)

# Everything else is DROPPED by default policy

COMMIT
EOF

# Create IPv6 rules file - block everything
cat > "${ROOTFS_DIR}/etc/iptables/rules.v6" << 'EOF'
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]

# Allow loopback only
-A INPUT -i lo -j ACCEPT
-A OUTPUT -o lo -j ACCEPT

# Block everything else

COMMIT
EOF

# Enable netfilter-persistent service
on_chroot << EOF
systemctl enable netfilter-persistent
EOF
