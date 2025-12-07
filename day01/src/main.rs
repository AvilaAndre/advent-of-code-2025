use std::{fs, path::Path};

#[derive(Debug)]
enum Operation {
    Left(i32),
    Right(i32),
}

fn get_operations_from_file(filename: &str) -> Vec<Operation> {
    let filepath = format!("res/{}", filename);
    let file_content =
        fs::read_to_string(Path::new(filepath.as_str())).expect("input file should have content");

    file_content
        .lines()
        .map(|l| {
            let (dir, num) = l.split_at(1);

            let parsed_num = num.parse::<i32>().expect("num should parse to i32");

            match dir {
                "L" => Operation::Left(parsed_num),
                "R" => Operation::Right(parsed_num),
                _ => panic!("dir should be R or L"),
            }
        })
        .collect()
}

fn sol1(ops: &Vec<Operation>) -> u32 {
    let mut count = 0;
    let mut pos: i32 = 50;

    for op in ops {
        match op {
            Operation::Left(val) => {
                pos -= val % 100;
                if pos < 0 {
                    pos = 100 + pos;
                }
            }
            Operation::Right(val) => {
                pos += val % 100;
                if pos >= 100 {
                    pos = pos - 100;
                }
            }
        }

        if pos == 0 {
            count += 1;
        }
    }

    count
}

fn sol2(ops: &Vec<Operation>) -> u32 {
    let mut count: u32 = 0;
    let mut pos: i32 = 50;

    for op in ops {
        match op {
            Operation::Left(val) => {
                // complete rotations
                count += (val - val % 100) as u32 / 100;

                let initial_pos = pos;
                pos -= val % 100;
                if pos < 0 {
                    pos = 100 + pos;
                    if initial_pos > 0 {count += 1};
                }

                if pos == 0 {
                    count += 1;
                }
            }
            Operation::Right(val) => {
                // complete rotations
                count += (val - val % 100) as u32 / 100;

                pos += val % 100;
                if pos >= 100 {
                    pos = pos - 100;
                    count += 1;
                }

            }
        }
    }

    count
}

fn main() {
    let ops = get_operations_from_file("input.txt");

    let answer1 = sol1(&ops);
    let answer2 = sol2(&ops);

    println!("Answer 1 is {answer1}");
    println!("Answer 2 is {answer2}");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sol1() {
        let example_ops = get_operations_from_file("example.txt");

        assert_eq!(sol1(&example_ops), 3);
    }

    #[test]
    fn test_sol2() {
        let example_ops = get_operations_from_file("example.txt");

        assert_eq!(sol2(&example_ops), 6);
    }

    #[test]
    fn test_sol3() {
        let example_ops = get_operations_from_file("input.txt");

        assert_eq!(sol2(&example_ops), 5961);
    }
}
