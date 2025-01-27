import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import request/queue

const anything_url = "https://httpbin.org/anything"

fn request_callback(url: String) {
  url
}

pub fn request_1_test() {
  process.sleep(10)
  io.println_error("\n\n")
  let q = queue.start(request_callback)
  let res = process.try_call(q, queue.new_request(_, anything_url), 4500)

  res |> should.be_ok
  let assert Ok(res) = res
  io.println_error(res)
}

pub fn request_10_test() {
  let q = queue.start(request_callback)
  let receiver = process.new_subject()
  list.range(0, 10)
  |> list.map(fn(i) {
    let url = anything_url <> "/" <> int.to_string(i)
    process.send(q, queue.new_request(receiver, url))
  })

  list.range(0, 10)
  |> list.map(fn(i) {
    let url = anything_url <> "/" <> int.to_string(i)
    process.receive(receiver, 100)
    |> should.equal(Ok(url))
  })
}

fn concurrency_test() {
  process.sleep(5)
  io.println_error("")
  let q =
    queue.start(fn(i) {
      let prefix =
        string.repeat(
          " ",
          i
            |> string.split("/")
            |> list.last
            |> result.then(int.parse)
            |> result.unwrap(0),
        )
      io.println_error(prefix <> ">" <> i)
      process.sleep(300)
      let res = request_callback(i)
      io.println_error(prefix <> "<" <> i)
      res
    })
  let receiver = process.new_subject()
  list.range(0, 10)
  |> list.map(fn(i) {
    let url = anything_url <> "/" <> int.to_string(i)
    process.send(q, queue.new_request(receiver, url))
  })

  process.sleep(3000)
  list.range(0, 10)
  |> list.map(fn(i) {
    let url = anything_url <> "/" <> int.to_string(i)
    process.receive(receiver, 1000)
    |> should.equal(Ok(url))
  })
}
