fn main() {
    println!(
        "cargo:rustc-env=CIRCLE_SEARCH_TARGET={}",
        std::env::var("TARGET").unwrap()
    );
}
