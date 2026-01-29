pub fn example() {
    println!("Rustlib_cargo2: Rust function Example");
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