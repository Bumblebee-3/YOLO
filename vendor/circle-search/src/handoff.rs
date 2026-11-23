use anyhow::{Context, Result, bail};
use base64::{Engine, engine::general_purpose::STANDARD};
use std::{
    fs::File,
    io::{Read, Write},
    net::{TcpListener, TcpStream},
    process::{Command, Stdio},
    thread,
    time::{Duration, Instant},
};

pub fn html(png: &[u8], dimensions: (i32, i32)) -> String {
    include_str!("handoff.html")
        .replace("__IMAGE__", &STANDARD.encode(png))
        .replace(
            "__DIMENSIONS__",
            &format!("{},{}", dimensions.0, dimensions.1),
        )
}

fn respond(stream: &mut TcpStream, status: &str, body: &[u8], kind: &str) -> Result<()> {
    write!(
        stream,
        "HTTP/1.1 {status}\r\nContent-Type: {kind}\r\nContent-Length: {}\r\nCache-Control: no-store\r\nReferrer-Policy: no-referrer\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n",
        body.len()
    )?;
    stream.write_all(body)?;
    stream.flush()?;
    Ok(())
}

pub fn open(png: &[u8], dimensions: (i32, i32)) -> Result<()> {
    // The private, short-lived loopback URL avoids screenshot files and public image hosts.
    let listener =
        TcpListener::bind(("127.0.0.1", 0)).context("Cannot create Firefox handoff server")?;
    listener.set_nonblocking(true)?;
    let address = listener.local_addr()?;
    let mut random = [0u8; 24];
    File::open("/dev/urandom")?.read_exact(&mut random)?;
    let token: String = random.iter().map(|b| format!("{b:02x}")).collect();
    let path = format!("/{token}");
    let url = format!("http://{address}{path}");
    let page = html(png, dimensions);
    let mut firefox = Command::new("firefox")
        .args(["--new-tab", &url])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .context("Could not start Firefox. Install firefox and try again")?;
    eprintln!("Opening your selection in Firefox…");
    let deadline = Instant::now() + Duration::from_secs(60);
    while Instant::now() < deadline {
        if let Some(status) = firefox.try_wait()?
            && !status.success()
        {
            bail!("Firefox exited with {status}");
        }
        match listener.accept() {
            Ok((mut stream, _)) => {
                stream.set_read_timeout(Some(Duration::from_secs(2)))?;
                stream.set_write_timeout(Some(Duration::from_secs(5)))?;
                let mut request = Vec::new();
                let mut buf = [0u8; 1024];
                while request.len() < 8192 && !request.windows(4).any(|s| s == b"\r\n\r\n") {
                    match stream.read(&mut buf) {
                        Ok(0) | Err(_) => break,
                        Ok(n) => request.extend_from_slice(&buf[..n]),
                    }
                }
                let request = String::from_utf8_lossy(&request);
                let first = request.lines().next().unwrap_or("");
                let host = format!("host: {address}");
                if first == format!("GET {path} HTTP/1.1")
                    && request.lines().any(|l| l.to_ascii_lowercase() == host)
                {
                    respond(
                        &mut stream,
                        "200 OK",
                        page.as_bytes(),
                        "text/html; charset=utf-8",
                    )?;
                    return Ok(());
                }
                let _ = respond(&mut stream, "404 Not Found", b"Not found", "text/plain");
            }
            Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                thread::sleep(Duration::from_millis(40))
            }
            Err(e) => return Err(e.into()),
        }
    }
    bail!(
        "Firefox did not load the search page within 60 seconds. Check Firefox and run circle-search again."
    )
}
