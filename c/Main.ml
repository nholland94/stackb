open Core_kernel
open Cmdliner

let with_channel default open_fn close_fn channel_id fn arg =
  if channel_id = "-" then
    fn default arg
  else begin
    let channel = open_fn channel_id in
    let result = fn channel arg in
    close_fn channel;
    result
  end

let with_input_channel = with_channel stdin (In_channel.create ~binary:false) In_channel.close
let with_output_channel = with_channel stdout (Out_channel.create ~binary:true) Out_channel.close

let output_bytes ch = List.iter ~f:(Out_channel.output_char ch)

let stackbc source destination =
  with_input_channel source (fun () -> In_channel.input_all ch) ()
    |> Parser.parse
    |> Compiler.compile
    |> List.map ~f:Instructions.binary_of_instruction
    |> List.concat
    |> with_output_channel destination output_bytes

let source_filename =
  let doc = "The source $(docv) ('-' for stdin)." in
  Arg.(value & pos 0 string "-" & info [] ~docv:"FILENAME" ~doc)

let destination_filename =
  let doc = "The output $(docv) ('-' for stdout)." in
  Arg.(value & opt string "-" & info ["o", "output"] ~docv:"FILENAME" ~doc)

let term = Term.(const stackbc $ source_filename $ destination_filename)

let () = Term.(exit (eval (term, info "stackbc")))
