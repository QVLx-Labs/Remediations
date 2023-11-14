use std::process::{Command, Stdio};
use std::fs;
use std::path::Path;
use std::time::{SystemTime, Duration};
use regex::Regex;

fn main() {
    println!("Scanning for pyobfgood...");

    // Known malicious packages
    let malicious_packages = vec![
        "Pyobftoexe", "Pyobfusfile", "Pyobfexecute",
        "Pyobfpremium", "Pyobflight", "Pyobfadvance", "Pyobfuse",
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
            } else {
                found_malicious = true;
            }
        }
    }

    if !found_malicious {
        println!("No malicious packages found.");
    }

    // Monitoring Network Activity
    println!("Monitoring network activity for potential shenanigans...");
    let malicious_servers = ["transfer.sh", "nirsoft.net"];
    let output = match Command::new("ss").arg("-tupn").output() {
        Ok(output) => output,
        Err(_) => {
            println!("ss command not found. Skipping network activity check.");
            return;
        }
    };

    let connections = String::from_utf8_lossy(&output.stdout);
    let mut threat_found = false;
    for server in malicious_servers.iter() {
        if connections.contains(server) {
            println!("Potential threat connection found!!!!");
            threat_found = true;
            break;
        }
    }
    if !threat_found {
        println!("No suspicious connections found.");
    }

    // Monitor CPU activity
    println!("Monitoring CPU activity for potential shenanigans...");
    if let Err(_) = Command::new("ps").args(["-eo", "pid,ppid,cmd,%mem,%cpu", "--sort=-%cpu"]).status() {
        println!("ps command not found. Skipping CPU activity check.");
    }

    // Monitor VIPs to see if they've been modified recently
    println!("Checking modifications in VIP directories...");
    let vip_dirs = ["/etc", "/bin", "/sbin", "/usr/bin", "/usr/sbin"];
    let now = SystemTime::now();
    let mut modified_files = Vec::new();

    for dir in vip_dirs.iter() {
        if Path::new(dir).exists() {
            if let Ok(entries) = fs::read_dir(dir) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if let Ok(metadata) = path.metadata() {
                        if let Ok(modified) = metadata.modified() {
                            if let Ok(duration) = now.duration_since(modified) {
                                if duration < Duration::from_secs(2 * 24 * 60 * 60) { // 2 days
                                    modified_files.push(path);
                                }
                            }
                        }
                    }
                }
            } else {
                println!("Error reading directory: {}", dir);
            }
        }
    }

    if modified_files.is_empty() {
        println!("No recent modifications in VIP directories.");
    } else {
        println!("Recent modifications found in VIP directories:");
        for file in &modified_files {
            println!("Modified file: {:?}", file);
        }
    }

    println!("Pyobfgood scan complete.");
}
