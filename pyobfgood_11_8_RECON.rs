// $t@$h

use std::process::{Command};
use std::fs;
use std::path::Path;
use std::time::{SystemTime, Duration};
use std::net::IpAddr;
use netscan::host::{HostInfo, PortStatus};
use netscan::scanner::PortScanner;
use netscan::setting::ScanType;
use regex::Regex;
use pnet::datalink;
use dns_lookup::lookup_host;

fn main() {
    println!("Scanning for pyobfgood...");

    // Known malicious packages
    let malicious_packages = vec![
        "Pyobftoexe",
        "Pyobfusfile",
        "Pyobfexecute",
        "Pyobfpremium",
        "Pyobflight",
        "Pyobfadvance",
        "Pyobfuse",
    ];

    // Scan and remove malicious packages
    println!("Scanning Python packages...");
    let mut found_malicious = false;
    let output = match Command::new("pip").arg("freeze").output() {
        Ok(output) => output,
        Err(e) => {
            eprintln!("Failed to execute pip freeze: {}", e);
            return;
        }
    };

    let installed_packages = String::from_utf8_lossy(&output.stdout);

    for pkg in malicious_packages.iter() {
        if installed_packages.contains(pkg) {
            println!("THREAT FOUND!!! Removing {}...", pkg);
            if let Err(e) = Command::new("pip").args(["uninstall", "-y", pkg]).status() {
                eprintln!("Failed to uninstall package {}: {}", pkg, e);
            }
            else { found_malicious = true; }
        }
    }

    if !found_malicious { println!("No malicious packages found."); }

    // Monitoring Network Activity
    println!("Monitoring network activity for potential shenanigans...");
    let flagged_servers = ["transfer.sh", "nirsoft.net"];
    let output = match Command::new("ss").arg("-tupn").output() {
        Ok(output) => output,
        Err(_) => {
            println!("ss command not found. Skipping network activity check.");
            return;
        }
    };

    recon("127.0.0.1"); // Test recon on localhost only. Recon for suspicious left unhooked.
                        // This is for Red Team Blue Team simulation. USE ETHICALLY/LEGALLY.

    let connections = String::from_utf8_lossy(&output.stdout);
    let mut shenanigans = false;
    let mut suspicious_ips = Vec::new();
    let ip_regex = Regex::new(r"(?P<ip>\d{1,3}(\.\d{1,3}){3}):").unwrap();

    for server in flagged_servers.iter() {
        if connections.contains(server) {
            println!("Potential threat connection found!!!!");
            shenanigans = true;

            // Extract IPs for recon
            for cap in ip_regex.captures_iter(&connections) {
                if let Some(ip) = cap.name("ip") {
                    suspicious_ips.push(ip.as_str().to_string());
                }
            }
            break;
        }
    }

    if !shenanigans { println!("No suspicious connections found."); }
    else { for ip in suspicious_ips { recon(&ip); } }

    // Monitor CPU
    println!("Monitoring CPU activity for potential shenanigans...");
    if let Err(_) = Command::new("ps").args(["-eo", "pid,ppid,cmd,%mem,%cpu", "--sort=-%cpu"]).status() {
        println!("ps command not found. Skipping CPU activity check.");
    }

    // Monitor VIPs
    println!("Checking modifications in VIP directories...");
    let vip_dirs = ["/etc", "/bin", "/sbin", "/usr/bin", "/usr/sbin"];
    let now = SystemTime::now();
    let mut modified_files = Vec::new();

    for dir in vip_dirs.iter() {
        if !Path::new(dir).exists() { continue; }

        let entries = match fs::read_dir(dir) {
            Ok(entries) => entries,
            Err(_) => {
                println!("Error reading directory: {}", dir);
                continue;
            }
        };

        for entry in entries.flatten() {
            let path = entry.path();
            if let Ok(metadata) = path.metadata() {
                if let Ok(modified) = metadata.modified() {
                    if let Ok(duration) = now.duration_since(modified) {
                        let num_days = 1; // Number of days back to check
                        if duration < Duration::from_secs(num_days * 24 * 60 * 60) {
                            modified_files.push(path);
                        }
                    }
                }
            }
        }
    }

    if modified_files.is_empty() { println!("No recent modifications in VIP directories."); }
    else {
        println!("Recent modifications found in VIP directories:");
        for file in &modified_files { println!("Modified file: {:?}", file); }
    }

    println!("Pyobfgood scan complete.");
}

fn recon(ip_str: &str) {
    println!("Performing offensive recon on: {}", ip_str);
    let interfaces = datalink::interfaces();
    let interface = interfaces.into_iter()
                              .find(|iface| iface.is_up() && !iface.ips.is_empty())
                              .expect("No net interface found.");
    let ip = interface.ips[0].ip();

    let mut port_scanner = PortScanner::new(ip).expect("Error creating port scanner");
    let target: HostInfo = HostInfo::new_with_ip_addr(ip).with_ports(vec![22,    // SSH
                                                                          80,    // HTTP
                                                                          443,   // HTTPS
                                                                          21,    // FTP
                                                                          25,    // SMTP
                                                                          53,    // DNS
                                                                          110,   // POP
                                                                          143,   // IMAP
                                                                          3306,  // mysql
                                                                          3389,  // RDP
                                                                          139]); // NBT

    port_scanner.scan_setting.add_target(target);
    port_scanner.scan_setting.set_scan_type(ScanType::TcpSynScan);
    port_scanner.scan_setting.set_timeout(Duration::from_secs(10));
    port_scanner.scan_setting.set_wait_time(Duration::from_millis(500));

    let result = port_scanner.sync_scan();
    for host_info in &result.hosts {
        println!("IP: {} Domain: {}", host_info.ip_addr, host_info.host_name);
        for port_info in &host_info.ports {
            if port_info.status == PortStatus::Open {
                println!("Port: {} Status: {:?}", port_info.port, port_info.status);
            }
        }
    }
}
