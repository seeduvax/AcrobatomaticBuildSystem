pub fn example() {
    println!("Rustlib_cargo A: Rust function Example");
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_exec1() {
        assert_eq!(47, 47);
    }
}