do_test()
  
function do_test() {
  let text = "hello " + "world"; 
  foo(text);
}
  
function foo(input) {
  bar(input);
}
  
function bar(input) {
  console.log("{}", input);
  throw "Boom!";
}