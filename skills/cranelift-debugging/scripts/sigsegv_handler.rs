// SIGSEGV handler for debugging JIT crashes
// Copy this into your test file to pause on crash and allow debugger attachment
//
// Usage:
//   1. Add `libc = "0.2"` to dev-dependencies
//   2. Copy this module into your test file
//   3. Call `sigsegv_handler::install()` at the start of your test
//   4. When crash occurs, attach with: lldb -p <pid>

#[cfg(unix)]
pub mod sigsegv_handler {
    use std::io::Read;
    use std::sync::atomic::{AtomicBool, Ordering};

    static CAUGHT: AtomicBool = AtomicBool::new(false);

    extern "C" fn handler(sig: libc::c_int) {
        // Prevent recursive signals
        if CAUGHT.swap(true, Ordering::SeqCst) {
            std::process::abort();
        }

        let sig_name = match sig {
            libc::SIGSEGV => "SIGSEGV",
            libc::SIGBUS => "SIGBUS",
            libc::SIGFPE => "SIGFPE",
            libc::SIGILL => "SIGILL",
            _ => "UNKNOWN",
        };

        eprintln!("\n╔══════════════════════════════════════════════════════════╗");
        eprintln!("║  CAUGHT {sig_name} - Process paused for debugger attachment");
        eprintln!("╠══════════════════════════════════════════════════════════╣");
        eprintln!("║  PID: {}", std::process::id());
        eprintln!("║                                                          ║");
        eprintln!("║  Attach debugger:                                        ║");
        eprintln!("║    lldb -p {}                                      ", std::process::id());
        eprintln!("║    gdb -p {}                                       ", std::process::id());
        eprintln!("║                                                          ║");
        eprintln!("║  Then in debugger:                                       ║");
        eprintln!("║    bt          # backtrace                               ║");
        eprintln!("║    f 0         # select frame                            ║");
        eprintln!("║    di -p       # disassemble at PC                       ║");
        eprintln!("║    reg read    # show registers                          ║");
        eprintln!("╠══════════════════════════════════════════════════════════╣");
        eprintln!("║  Press Enter to continue (will crash)...                 ║");
        eprintln!("╚══════════════════════════════════════════════════════════╝");

        let mut buf = [0u8; 1];
        let _ = std::io::stdin().read(&mut buf);
    }

    /// Install signal handlers for common crash signals.
    /// Call this at the start of your test.
    pub fn install() {
        unsafe {
            libc::signal(libc::SIGSEGV, handler as usize);
            libc::signal(libc::SIGBUS, handler as usize);
            libc::signal(libc::SIGFPE, handler as usize);
            libc::signal(libc::SIGILL, handler as usize);
        }
        eprintln!("[sigsegv_handler] Installed crash handlers for PID {}", std::process::id());
    }
}

#[cfg(not(unix))]
pub mod sigsegv_handler {
    pub fn install() {
        eprintln!("[sigsegv_handler] Not available on this platform, use cdb/WinDbg instead");
    }
}

// Example test usage:
#[cfg(test)]
mod tests {
    #[test]
    fn test_with_crash_handler() {
        super::sigsegv_handler::install();

        // Your JIT test code here...
    }
}
