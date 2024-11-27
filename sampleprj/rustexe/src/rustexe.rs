pub fn example() {
    println!("Rustexe: Rust exec Example");

    rustlib::rustlib::example();

    let data1 = rustlib::rustlib::DataStruct1::new();
    data1.print_something();
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_exec() {
        assert_eq!(47, 47);
    }
}