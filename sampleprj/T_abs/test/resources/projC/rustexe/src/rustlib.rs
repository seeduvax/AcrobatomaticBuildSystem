pub fn example() {
    println!("Rustexe_cargo: Rust function Example");
    projA_rustlibA::rustlib::example();
    projB_rustlibB::rustlib::example();
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_exec1() {
        assert_eq!(47, 47);
    }
}