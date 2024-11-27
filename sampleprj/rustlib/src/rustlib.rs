extern "C" {
    // absolute function of std library
    fn abs(input: i32) -> i32;
}

pub fn example() {
    println!("Rustlib: Rust function Example");
}

pub struct DataStruct1 {

}

impl DataStruct1 {
    pub fn new() -> DataStruct1 {
        DataStruct1 {}
    }

    pub fn print_something(&self) {
        println!("Something");
        let val: i32;
        unsafe {
            val = abs(-32);
        }
        println!(" => {}", val);
    }
}


#[cfg(test)]
mod tests {
    #[test]
    fn test_exec() {
        assert_eq!(43, 43);
    }
}