import gleam/erlang/process
import gleam/io
import gleeunit/should
import request/queue

const anything_url = "https://httpbin.org/anything"

pub fn request_3_test() {
  process.sleep(10)
  io.println_error("\n\n")
  let q = queue.start()
  let res = process.try_call(q, queue.new_request_subj(_, anything_url), 4500)

  res |> should.be_ok
}
