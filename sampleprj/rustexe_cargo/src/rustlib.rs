pub fn example() {
    println!("Rustexe_cargo: Rust function Example");
    rustlib_cargo::rustlib::example();
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_exec1() {
        assert_eq!(47, 47);
    }

    #[test]
    fn test_exec2() {
        assert_eq!(40, 40);
    }
}